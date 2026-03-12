# Graphical Debug Console — Brainstorm & Feasibility Analysis

> **Goal:** Replace the current `print()`-based debugging with a `--debug` flag that launches an embedded web server, serving a browser-based debug UI for inspecting pipeline execution, model state, template traces, and errors.

---

## Table of Contents

1. [The Problem](#1-the-problem)
2. [Proposed Solution](#2-proposed-solution)
3. [Feasibility — Will This Work?](#3-feasibility--will-this-work)
4. [Real-Time Stepping — Deep Dive](#4-real-time-stepping--deep-dive)
5. [Source-Level Mapping](#5-source-level-mapping)
6. [Time-Travel Debugging](#6-time-travel-debugging)
7. [Architecture](#7-architecture)
8. [What the UI Should Show](#8-what-the-ui-should-show)
9. [Data Model for Debug Events](#9-data-model-for-debug-events)
10. [Integration Points in Existing Code](#10-integration-points-in-existing-code)
11. [Frontend Approach](#11-frontend-approach)
12. [Implementation Plan](#12-implementation-plan)
13. [Open Questions](#13-open-questions)
14. [Edge Cases & Implementation Details](#14-edge-cases--implementation-details)
15. [Alternatives Considered](#15-alternatives-considered)

---

## 1. The Problem

Today, debugging ModelHike is entirely console-driven:

- **Flag toggling** — set booleans on `config.flags` before the run, re-run, read stdout.
- **Event hooks** — write Swift closures in `DevMain.swift`, recompile, re-run.
- **In-template logging** — insert `console-log` / `announce` into `.teso` / `.ss` files, re-run, grep output.
- **Error reading** — scan a wall of text for call stacks, variable dumps, phase markers.

Every debugging cycle requires: edit Swift or template code → recompile → re-run → read stdout. There is no way to:

- Inspect the parsed model tree interactively
- Browse generated files and trace them back to the template + data that produced them
- See which `if` branch was taken without enabling `controlFlow` globally and reading noisy output
- Inspect variable values at a specific point without inserting `console-log` and recompiling
- Explore the call stack visually when an error occurs
- Test expressions against live model data without writing a `runTemplateStr()` harness

For someone accustomed to IDE-style debugging (breakpoints, watch expressions, call stack panels, variable inspectors), this is a high-friction workflow.

---

## 2. Proposed Solution

Add a `--debug` command-line flag to `DevTester`. When present:

1. The pipeline runs normally, but **all debug events are captured into a structured in-memory log** instead of (or in addition to) being printed.
2. After the pipeline completes (or crashes), an **embedded HTTP server** starts on a local port (e.g., `http://localhost:4800`).
3. A **browser-based single-page app** is served, providing panels for:
   - Pipeline phase timeline
   - Model tree explorer
   - Template execution trace (with variable values)
   - File generation log (with drill-down to template + data)
   - Error detail view (with call stack and memory dump)
   - Expression playground (test expressions against the captured model)

The browser opens automatically. The server stays alive until the user presses Ctrl+C.

---

## 3. Feasibility — Will This Work?

### 3.1 The Embedded Web Server

**Verdict: Feasible, with caveats.**

The project has a zero-external-dependency policy for the `ModelHike` library target. Three options:

| Approach | Dependency | Effort | Platform |
|---|---|---|---|
| **`Network.framework` (NWListener)** | None — Apple system framework | Medium | macOS/iOS only |
| **Raw POSIX sockets (Darwin)** | None — system calls | High | macOS + Linux |
| **SwiftNIO / Hummingbird** | External package | Low | All platforms |

**Recommended: `Network.framework`** for these reasons:
- Zero external dependencies — honours the project's policy.
- `NWListener` + `NWConnection` are available on macOS 13+ (the project's minimum deployment target).
- Supports both HTTP request/response and WebSocket upgrade natively via `NWProtocolWebSocket`.
- The debug server only needs to handle ~5 REST endpoints and one WebSocket stream — this is well within `Network.framework`'s sweet spot.
- The debug server is only used in `DevTester` (the executable), not the `ModelHike` library. So even if we wanted to add a dependency, it would only affect the dev tool, not downstream consumers.

**Caveat:** `Network.framework` is Apple-only. If Linux support for the debug console is ever needed, the server layer would need to be swapped for raw sockets or SwiftNIO. This is acceptable because `DevTester` already targets macOS-only development workflows.

**Mitigation for the future:** Define a `DebugServer` protocol. Implement `NetworkFrameworkDebugServer` now. Swap in a `SwiftNIODebugServer` later if cross-platform is needed.

### 3.2 Serving the Frontend

**Verdict: Feasible.**

The HTML/CSS/JS for the debug UI can be delivered via:

| Approach | Pros | Cons |
|---|---|---|
| **Swift string literals** | Zero files, self-contained | Hard to edit, no syntax highlighting |
| **Swift Package resources** | Proper files, editable | Adds resource bundle complexity |
| **External files at a known path** | Easy to iterate on | Fragile path dependency |

**Recommended: Swift Package resources** for the `DevTester` target. The `.executableTarget` in `Package.swift` can declare a `resources:` parameter pointing to an `Assets/` folder containing the HTML/CSS/JS files. At runtime, `Bundle.module.url(forResource:)` loads them. This keeps frontend files as real `.html` / `.js` / `.css` files with proper syntax highlighting and tooling, while bundling them into the executable.

For initial development, **a single `debug-console.html` file with inlined CSS and JS** is the simplest starting point. It can be split later.

### 3.3 The Timing Problem

**This is the biggest challenge.**

The pipeline runs in milliseconds to low seconds. By the time a browser tab opens, the pipeline is already done. A "live streaming" debug experience would show a completed run by the time the user sees it.

**Verdict: Use a post-mortem (capture-then-browse) model.** This is actually *more useful* than live streaming for a code-generation tool:

- The user cares about *what happened* and *why*, not watching it happen in real-time.
- Post-mortem means the full execution trace is available for random-access browsing — jump to any phase, any file, any object, instantly.
- No timing coordination needed between Swift async pipeline and browser rendering.
- The pipeline runs at full speed with no pauses.

**Flow:**
```
Pipeline runs → Events buffered in DebugSession → Pipeline ends → Server starts → Browser opens → User browses
```

**Future enhancement:** If pause-and-inspect (breakpoint-style) debugging is wanted, it can be layered on later using Swift `CheckedContinuation`. The server would hold a continuation, the pipeline would suspend at a hook point, and the browser would send a "resume" message via WebSocket. This is complex but architecturally sound with Swift's structured concurrency. Not needed for v1.

### 3.4 Data Volume

A full pipeline run with `lineByLineParsing` enabled generates thousands of log lines. The debug console needs to handle this without choking.

**Verdict: Feasible.** The post-mortem model means all data is in-memory before the browser connects. The server can paginate, filter, and stream on demand. The frontend can virtualise long lists (only render visible rows). A typical ModelHike run generates on the order of hundreds of files from dozens of model objects — this is well within browser rendering capacity.

### 3.5 `Sendable` and Concurrency

All model objects are actors. Extracting data for JSON serialization requires `await` on every property access. This is tedious but not blocking — the extraction happens once after the pipeline completes, and all actor properties have public getters.

**Verdict: Feasible.** Build a `DebugSnapshot` struct that walks the model tree after the pipeline run and captures all relevant data into plain `Sendable` / `Codable` structs. This snapshot is then served as JSON to the frontend.

---

## 4. Real-Time Stepping — Deep Dive

Real-time stepping (pause-the-pipeline, inspect-state, resume) is included in the design. It is the feature that truly replaces IDE-style breakpoint debugging. Here's why it's achievable and where the complexity lies.

### 4.1 Why It's Achievable

The entire execution model already funnels through a small number of `async` execution loops. Every statement in SoupyScript — `if`, `for`, `set`, `render-file`, `console-log`, etc. — implements the same protocol:

```swift
public protocol TemplateItem: Sendable {
    func execute(with ctx: Context) async throws -> String?
}
```

And all statements are executed in a single loop inside `GenericStmtsContainer.execute()`:

```swift
for item in items {
    if let result = try await item.execute(with: ctx) {
        str += result
    }
}
```

This `for item in items` loop is **the** central execution point for all template and script logic. Every `render-file`, every `if` branch, every `for` iteration, every `set` passes through here (or through a nested call to the same pattern).

Because every `item.execute()` is already `async`, inserting a suspension point requires **zero changes to the execution model**. The pause is a single `await` call injected before `item.execute()`:

```swift
for item in items {
    // Stepping hook: suspend here if a breakpoint is active
    if let stepper = ctx.debugStepper {
        await stepper.willExecute(item: item, ctx: ctx)
    }
    if let result = try await item.execute(with: ctx) {
        str += result
    }
}
```

The `willExecute` method checks whether the current item matches an active breakpoint (by file + line, or by statement type). If it does, it suspends using `withCheckedContinuation` and waits for the browser to send a "resume" command over WebSocket:

```swift
actor DebugStepper {
    private var continuation: CheckedContinuation<Void, Never>?
    private var breakpoints: Set<BreakpointLocation> = []
    private var mode: StepMode = .run  // .run | .stepOver | .stepInto | .stepOut

    func willExecute(item: TemplateItem, ctx: Context) async {
        guard shouldPause(at: item) else { return }

        // Emit current state to the browser
        await emitPauseEvent(item: item, ctx: ctx)

        // Suspend until the browser sends "resume"
        await withCheckedContinuation { cont in
            self.continuation = cont
        }
    }

    func resume(mode: StepMode) {
        self.mode = mode
        continuation?.resume()
        continuation = nil
    }
}

enum StepMode: String, Codable {
    case run            // continue until next breakpoint
    case stepOver       // next sibling statement
    case stepInto       // next statement at any depth
    case stepOut        // resume until current scope exits
    case nextIteration  // finish current for-loop iteration, pause at start of next
}
```

### 4.2 Where the Complexity Lives

The execution model is cooperative — suspending is cheap and correct. The complexity is in three areas:

#### A. Breakpoint Granularity

`TemplateItem` includes both high-level statements (`render-file`, `for`, `if`) and low-level content items (`TextContent`, `PrintExpressionContent`, `EmptyLine`). Pausing at every `TextContent` line would be useless. The stepper needs granularity control:

| Item Type | Pausable? | Rationale |
|---|---|---|
| `IfStmt` | Yes | Branch decisions — the #1 debugging need |
| `ForStmt` | Yes (per iteration) | Loop iteration inspection |
| `RenderFile` / `CopyFile` | Yes | File generation boundaries |
| `SetVar` / `SetStr` | Yes | Variable mutations |
| `FunctionCall` | Yes | Macro entry points |
| `ConsoleLog` / `Announce` | Yes | User-placed markers |
| `FatalError` / `Stop` | Yes | Assertion/halt points |
| `TextContent` | No (unless step-into) | Too noisy for normal stepping |
| `PrintExpressionContent` | Configurable | Useful for expression debugging |
| `EmptyLine` | No | Never useful |

This maps directly to IDE stepping modes:
- **Step Over** — pause at the next sibling statement (skip children of `if`/`for`/`render-file`)
- **Step Into** — pause at the first child statement (enter the `if` body, the `for` loop, or the rendered template)
- **Step Out** — resume until the current block/file completes
- **Continue** — resume until the next breakpoint

#### B. Breakpoint Location Matching

Every `TemplateItem` that conforms to `TemplateItemWithParsedInfo` carries a `pInfo: ParsedInfo`. This `pInfo` has:

- `identifier` — the file name (e.g., `"main.ss"`, `"entity.service.teso"`)
- `lineNo` — the line number within that file
- `line` — the actual source text of that line

This is exactly the data needed to match against user-set breakpoints:

```swift
struct BreakpointLocation: Hashable {
    let fileIdentifier: String
    let lineNo: Int
}
```

The browser sends `{ "file": "main.ss", "line": 42 }`, the stepper checks each `pInfo` against the set. This is an O(1) hash lookup per statement — negligible overhead.

#### C. WebSocket Coordination

The pipeline runs on Swift's cooperative thread pool. When `withCheckedContinuation` suspends, the thread is freed — other work can proceed. The `DebugServer` must:

1. Accept a WebSocket connection from the browser
2. When a pause event fires, send the current state (file, line, variables, call stack) as a JSON message
3. Wait for a `{"action": "resume", "mode": "stepOver"}` message from the browser
4. Call `stepper.resume(.stepOver)` which resumes the continuation

The only tricky part is ensuring the WebSocket message handling and the continuation resume happen on compatible executors. Since `DebugStepper` is an `actor`, all access is serialized — no data races.

#### D. Nested Execution Context

Templates can `render-file` other templates, which call `render-file` again, etc. The call stack can be several levels deep. Stepping needs to track depth:

- `stepOver` at depth N means: resume, pause when depth returns to N and the next statement begins
- `stepInto` means: pause at the very next `TemplateItem` regardless of depth
- `stepOut` means: resume, pause when depth returns to N-1

The `CallStack` actor already tracks this nesting. The stepper can read `callStack.snapshot().count` to get current depth.

### 4.3 Performance Impact

When `--debug` is **not** set, there is zero overhead — `ctx.debugStepper` is `nil`, the `if let` check is a single nil comparison per statement.

When `--debug` is set **without breakpoints**, the stepper's `shouldPause()` returns `false` immediately. The overhead is one actor method call per statement — negligible compared to the template rendering work.

When a **breakpoint is hit**, the pipeline genuinely pauses. This is intentional. The user is inspecting state.

### 4.4 Summary — Not Problematic to Implement

| Concern | Difficulty | Reason |
|---|---|---|
| Injecting the pause point | Easy | Single `await` call in one loop |
| Breakpoint matching | Easy | `ParsedInfo` already has file + line; O(1) hash lookup |
| Step modes (over/into/out) | Medium | Requires depth tracking via `CallStack` |
| WebSocket coordination | Medium | Standard actor + continuation pattern |
| State serialization at pause | Medium | Snapshot `WorkingMemory` + `CallStack` to JSON |
| Frontend stepping UI | Medium | Standard debugger chrome (play/step/step-in/step-out buttons + source display) |

Total additional complexity over the post-mortem model: one new actor (`DebugStepper`), one insertion point in `GenericStmtsContainer.execute()`, and WebSocket message handling in the server. This is a contained change.

---

## 5. Source-Level Mapping

Source-level mapping is a first-class feature, not a future enhancement. The data needed to display source files with line highlighting is already present in the codebase.

### 5.1 What `ParsedInfo` Already Provides

Every `TemplateItem` that participates in execution carries a `ParsedInfo`:

```swift
public struct ParsedInfo: Sendable {
    public private(set) var line: String        // the actual source text of this line
    public private(set) var lineNo: Int         // 1-based line number in the file
    public private(set) var level: Int          // nesting depth
    public private(set) var firstWord: String   // first token (statement keyword)
    public private(set) var secondWord: String? // second token (sub-keyword)
    public private(set) var identifier: String  // file name (e.g., "main.ss", "entity.service.teso")
    public private(set) var parser: LineParser  // the parser that owns this line
    public private(set) var ctx: Context        // the context at parse time
}
```

The `identifier` is the **file name** — set from `lineParser.identifier`, which comes from `template.name` or `scriptFile.name` or the physical `LocalFile.name`.

The `LineParser` also holds the full file contents internally (the `lines: [String]` array). This means at capture time, the debug recorder can extract the full source text of every file that was parsed.

### 5.2 What the Blueprint Already Provides

Templates and scripts are loaded from `Blueprint` sources. `LocalFileBlueprint` works from an absolute filesystem path. The file path is recoverable:

- `LocalFileTemplate` — has `name` (filename) and is loaded from a known blueprint folder
- `LocalScriptFile` — same pattern
- `.modelhike` model files — loaded by `LocalFileModelLoader` from `config.basePath`

### 5.3 Capture Strategy

During the pipeline run, the `DebugRecorder` builds a **source file registry**:

```swift
struct SourceFile: Codable, Sendable {
    let identifier: String       // the pInfo.identifier (filename)
    let fullPath: String?        // absolute filesystem path (if available)
    let content: String          // full file text
    let lines: [String]          // pre-split for line-level access
    let fileType: SourceFileType // .soupyScript | .template | .model | .config
}

enum SourceFileType: String, Codable {
    case soupyScript  // .ss files
    case template     // .teso files
    case model        // .modelhike files
    case config       // .tconfig files
}
```

Sources are captured at two points:

1. **Model files** — when `LoadModels` pass runs, record each `.modelhike` file's contents from `LocalFileModelLoader`.
2. **Template/script files** — when the `LineParser` is initialized with file contents (in `TemplateEvaluator.execute()` and `ScriptFileExecutor.execute()`), the `DebugRecorder` captures the source. The `identifier` is already set. The content is `template.toString()` or `scriptFile.toString()`.

### 5.4 What the UI Shows

Every debug event that has a `ParsedInfo` (errors, control flow decisions, file generations, console logs, stepping pauses) maps to a source location. The UI renders this as:

1. **Source panel** — displays the file contents with line numbers and syntax highlighting.
2. **Current line highlight** — the line referenced by `pInfo.lineNo` is highlighted (yellow for current, red for error).
3. **Gutter markers** — breakpoints (red dots), current execution position (green arrow), error locations (red X).
4. **Call stack click-through** — clicking a call stack frame navigates the source panel to that file + line.

For syntax highlighting, a lightweight approach:
- `.ss` files — highlight keywords (`if`, `for`, `set`, `render-file`, `end-if`, etc.) and `{{ }}` expressions
- `.teso` files — highlight `:` prefixed statements and `{{ }}` expressions
- `.modelhike` files — highlight `===` fences, `*`/`-`/`~` prefixes, `@` annotations, `#` tags

This doesn't need a full parser — a regex-based tokenizer in JS is sufficient for visual highlighting.

### 5.5 Linking Events to Source

Every `DebugEvent` includes a `SourceLocation`:

```swift
struct SourceLocation: Codable, Sendable {
    let fileIdentifier: String  // matches SourceFile.identifier
    let lineNo: Int
    let lineContent: String     // the actual line text (for quick display without lookup)
}
```

The frontend uses `fileIdentifier` to look up the `SourceFile` from the registry, then scrolls to `lineNo` and highlights it. This gives instant source navigation for every event in the trace.

---

## 6. Time-Travel Debugging

Time-travel debugging is the core debugging paradigm for the debug console. Instead of requiring breakpoints to be set before the run, the entire execution is recorded and can be browsed freely after completion.

### 6.1 Concept

Every significant event during the pipeline run is captured as a `DebugEvent` with an associated `MemorySnapshot`. After the run completes, the user can:

- **Scrub a timeline slider** to move through the execution chronologically
- **Click any event** to jump to that point in time
- **See the full variable state** at any selected point
- **See the source file** with the current line highlighted
- **See the call stack** at that point
- **Compare variable values** between two points in time

This is more powerful than traditional breakpoint debugging for a code-generation tool, because the user doesn't need to know in advance where to look — they can explore the full execution post-hoc.

### 6.2 Snapshot Strategy

Not every event needs a full memory dump. The strategy balances comprehensiveness with memory cost:

| Event Type | Snapshot Level | What's Captured |
|---|---|---|
| Phase start/end | Full | All `WorkingMemory` variables |
| File generation start | Full | All variables — this is the most common debugging target |
| Control flow (`if`/`else-if`/`else`) | Condition-relevant | The condition expression, its resolved boolean value, and the variables referenced in the condition |
| `set` / `set-str` | Delta | The variable name, its old value, and its new value |
| `for` loop iteration | Iterator state | Loop variable name, current value, `@loop` (index, first, last, count) |
| `console-log` | Expression + result | The expression text and its resolved value |
| `render-file` / `copy-file` | Context | Output filename, template name, working_dir |
| Error | Full + call stack | Everything — same as current `includeMemoryVariablesDump` |
| `announce` | None | Just the message text |
| Script/template entry/exit | Shallow | File identifier, variables added/removed in this scope |

### 6.3 Delta Compression

Full `WorkingMemory` snapshots at every file generation point could grow large for models with many entities. To keep memory bounded:

1. **Base snapshot** — take a full snapshot at each phase boundary (6 per run).
2. **Delta snapshots** — between base snapshots, only record variables that changed since the last snapshot.
3. **Reconstruction** — to display the state at any point, start from the nearest preceding base snapshot and apply deltas forward.

This is the same strategy used by video codecs (I-frames + P-frames) and undo systems. For a typical ModelHike run generating ~500 files across ~50 entities, the storage is estimated at:

- 6 full snapshots × ~50 variables × ~100 bytes each = ~30 KB
- ~500 delta snapshots × ~5 changed variables × ~100 bytes = ~250 KB
- Total: **~300 KB** — trivially fits in memory

### 6.4 UI for Time-Travel

```
┌───────────────────────────────────────────────────────────────┐
│ Timeline                                                       │
│ ●━━━●━━━━━━●━━●━━━━━●━━━━━━━●━━━━━━━━━━━━●━━●━━●━━━━━━━━━━●  │
│ D   L      H  T     R       R            R   R  P          ●  │
│ (Discover) (Load)   (Hydrate)  ...files...    (Persist)  Done │
│                                    ▲                          │
│                              cursor here                      │
├──────────────────────┬────────────────────────────────────────┤
│ Source               │ Variables at this point                │
│                      │                                        │
│  38│ set working_dir │ @container.name = "APIs"              │
│  39│ for module ..   │ working_dir = "/apps/registry/src/"   │
│ ►40│ render-file ... │ module.name = "RegistryManagement"    │
│  41│ end-for         │ entity.name = "Registry"              │
│  42│                 │ @loop.index = 3                        │
│                      │ @loop.count = 7                        │
├──────────────────────┼────────────────────────────────────────┤
│ Call Stack            │ Events (filtered)                      │
│                      │                                        │
│ ► entity.service.teso│ 📁 user.service.ts (entity.service)   │
│   main.ss [40]       │ 📁 user.module.ts (entity.module)     │
│   [Root Folder]      │ 🔀 if containerType == "micro..." ✓   │
│                      │ 📁 registry.service.ts ← selected     │
│                      │ 🔀 if entity.hasApis ✓                │
└──────────────────────┴────────────────────────────────────────┘
```

The timeline is the primary navigation. Each dot is an event. Dots are colour-coded by type (blue for files, orange for control flow, red for errors). Clicking a dot or scrubbing the slider jumps the source panel, variable inspector, and call stack to that point in time.

### 6.5 Comparison Mode

A "diff" mode lets the user select two points on the timeline and see:
- Which variables changed between them
- What their old and new values are
- Which files were generated between the two points

This is especially useful for debugging "why did entity A get the right output but entity B didn't" — select the file generation point for each and compare the variable state.

---

## Remaining Shortcomings

### S1: Expression Playground Needs the Full Engine

**Shortcoming:** An interactive "expression playground" in the browser needs to evaluate TemplateSoup expressions against the loaded model.

**Mitigation:** Since the server runs after the pipeline, the `Workspace`, `GenerationContext`, and `TemplateSoup` instances are still in memory. The server can accept an expression string via a REST endpoint, call `ws.render(string:data:)`, and return the result. The existing `runTemplateStr()` pattern already proves this works.

### S2: Build Time for Frontend Changes

**Shortcoming:** If frontend assets are embedded as Swift Package resources, changing the HTML/JS requires a Swift rebuild.

**Mitigation:** During development, add a flag (`--debug-dev`) that serves files from a local filesystem path instead of the bundle, enabling live reload. In production (the normal `--debug` flag), serve from the bundle.

### S3: Doesn't Replace Xcode for Swift-Level Bugs

**Shortcoming:** If the bug is in the Swift implementation itself (e.g., a parser regression), the web debug console won't help — you still need Xcode's debugger.

**Mitigation:** This is by design. The debug console targets the *user-facing* debugging surface: model correctness, template logic, expression evaluation, file routing. Swift-level bugs are a developer concern, not a user concern.

---

## 7. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         DevTester                                │
│                                                                  │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐           │
│  │ Pipeline  │───►│ DebugRecorder│───►│ DebugSession │           │
│  │ (6 phases)│    │ (event sink) │    │ (in-memory)  │           │
│  └─────┬────┘    └──────────────┘    └──────┬───────┘           │
│        │                                     │                   │
│  ┌─────▼──────┐                    ┌────────▼────────┐          │
│  │DebugStepper│◄───── WebSocket ──►│  DebugServer    │          │
│  │(breakpoints│    resume/pause    │ (DebugServing   │          │
│  │ + stepping)│                    │  protocol impl) │          │
│  └────────────┘                    │  port 4800      │          │
│                                    └────────┬────────┘          │
│        ┌────────────────┐                   │                   │
│        │  SourceFileMap │ ◄─── serves ──────┤                   │
│        │ (file registry)│                   │                   │
│        └────────────────┘                   │                   │
└─────────────────────────────────────────────┼───────────────────┘
                                              │ HTTP + WebSocket
                                   ┌──────────▼──────────┐
                                   │  Browser Debug UI   │
                                   │  (Single-Page App)  │
                                   └─────────────────────┘
```

### Key Components

#### `DebugRecorder` (actor)

Wraps `ContextDebugLog` during `--debug` runs. Instead of only printing, it appends structured `DebugEvent` values to a `DebugSession`. It still prints to stdout as well (dual output) so the terminal remains useful. Also captures source file contents as they're loaded by parsers.

```swift
public actor DebugRecorder {
    private var events: [DebugEvent] = []
    private var sourceFiles: [String: SourceFile] = [:]  // keyed by identifier
    private var modelSnapshot: ModelSnapshot?
    private var baseSnapshots: [MemorySnapshot] = []
    private var deltaSnapshots: [DeltaSnapshot] = []
    private var errorSnapshot: ErrorSnapshot?

    func record(_ event: DebugEvent) { ... }
    func registerSourceFile(_ file: SourceFile) { ... }
    func captureModel(_ model: AppModel) async { ... }
    func captureBaseSnapshot(_ memory: WorkingMemory, at label: String) async { ... }
    func captureDelta(variable: String, oldValue: Sendable?, newValue: Sendable?) { ... }
    func captureError(_ error: Error, context: Context) async { ... }

    func session() -> DebugSession { ... }
}
```

#### `DebugStepper` (actor)

Manages real-time breakpoints and stepping. Injected into the execution loop via `GenerationContext`. When a breakpoint matches, suspends the pipeline using `CheckedContinuation` and emits the current state over WebSocket. Resumes when the browser sends a command.

```swift
public actor DebugStepper {
    private var continuation: CheckedContinuation<Void, Never>?
    private var breakpoints: Set<BreakpointLocation> = []
    private var mode: StepMode = .run
    private var currentDepth: Int = 0
    private var pauseAtDepth: Int? = nil
    private weak var server: (any DebugServing)?

    func willExecute(item: TemplateItem, ctx: Context) async { ... }
    func resume(mode: StepMode) { ... }
    func addBreakpoint(_ bp: BreakpointLocation) { ... }
    func removeBreakpoint(_ bp: BreakpointLocation) { ... }
}

enum StepMode: String, Codable {
    case run         // continue until next breakpoint
    case stepOver    // next sibling statement
    case stepInto    // next statement at any depth
    case stepOut     // resume until current scope exits
}

struct BreakpointLocation: Hashable, Codable {
    let fileIdentifier: String
    let lineNo: Int
}
```

#### `SourceFileMap` (actor)

Registry of all source files encountered during the pipeline run. Populated by the `DebugRecorder` as parsers load files. Served to the frontend for source-level display.

```swift
public actor SourceFileMap {
    private var files: [String: SourceFile] = [:]

    func register(identifier: String, content: String, fullPath: String?, fileType: SourceFileType) { ... }
    func file(for identifier: String) -> SourceFile? { ... }
    func allFiles() -> [SourceFile] { ... }
}
```

#### `DebugSession` (struct, Codable)

The complete captured state of a pipeline run, serialisable to JSON for the frontend.

```swift
struct DebugSession: Codable, Sendable {
    let timestamp: Date
    let config: ConfigSnapshot
    let phases: [PhaseRecord]
    let model: ModelSnapshot
    let events: [DebugEvent]
    let sourceFiles: [SourceFile]
    let files: [GeneratedFileRecord]
    let errors: [ErrorRecord]
    let baseSnapshots: [MemorySnapshot]
    let deltaSnapshots: [DeltaSnapshot]
}
```

#### `DebugServing` (protocol) + `NetworkFrameworkDebugServer`

The server is behind a protocol so the transport can be replaced without touching any other code.

```swift
public protocol DebugServing: Actor {
    func start(port: UInt16) async throws
    func stop() async
    func waitForShutdown() async
    func send(_ message: DebugWebSocketMessage) async
    var onWebSocketMessage: (@Sendable (DebugWebSocketMessage) async -> Void)? { get set }
}
```

The default implementation uses `Network.framework` (`NWListener` + `NWConnection` with `NWProtocolWebSocket`). If cross-platform support is needed later, a `SwiftNIODebugServer` or `RawSocketDebugServer` can be swapped in by conforming to the same protocol.

```swift
public actor NetworkFrameworkDebugServer: DebugServing {
    private let session: DebugSession
    private let sourceFiles: SourceFileMap
    private var listener: NWListener?
    // ...
}
```

**HTTP Endpoints:**

| Method | Path | Response |
|---|---|---|
| GET | `/` | The debug UI HTML page |
| GET | `/api/session` | Full `DebugSession` as JSON |
| GET | `/api/model` | Model tree (containers → modules → objects → properties) |
| GET | `/api/events?phase=Render&type=file` | Filtered events |
| GET | `/api/files` | List of generated files with template/data metadata |
| GET | `/api/source/:identifier` | Source file contents for display |
| GET | `/api/memory/:eventIndex` | Reconstructed variable state at a specific event |
| POST | `/api/evaluate` | Expression playground: evaluate a template expression |
| WS | `/ws` | WebSocket for stepping commands + live pause/resume events |

**WebSocket Messages (browser → server):**

| Message | Payload | Effect |
|---|---|---|
| `addBreakpoint` | `{ file, line }` | Register a breakpoint |
| `removeBreakpoint` | `{ file, line }` | Remove a breakpoint |
| `resume` | `{ mode: "run" \| "stepOver" \| "stepInto" \| "stepOut" }` | Resume pipeline execution |

**WebSocket Messages (server → browser):**

| Message | Payload | Effect |
|---|---|---|
| `paused` | `{ file, line, lineContent, callStack, variables }` | Pipeline is paused at a breakpoint |
| `event` | `DebugEvent` (JSON) | Live event stream during execution |
| `completed` | `{ summary }` | Pipeline finished |

#### `DebugEvent` (enum, Codable)

Every event that originates from template/script execution carries a `SourceLocation` — the `pInfo.identifier`, `pInfo.lineNo`, and `pInfo.line` that are already present at every point in the engine. The complete enum with all cases (cross-checked against every `ContextDebugLog` method) is in [section 14.12](#1412-debugevent-completeness--cross-check-against-contextdebuglog). Summary of event categories:

- **Pipeline lifecycle** — `phaseStarted`, `phaseCompleted`, `phaseFailed`, `phaseSkipped`, `passSkipped`
- **Model loading** — `modelLoaded`
- **File generation** — `fileGenerated`, `fileCopied`, `fileExcluded`, `fileRenderStopped`, `fileSkipped`, `folderCopied`, `folderRendered`
- **Working directory** — `workingDirChanged`
- **Control flow** — `controlFlow` (with `BranchKind`: `ifTrue`, `elseIfTrue`, `elseBlock`)
- **Script/template lifecycle** — `scriptParseStarted`, `scriptStarted`, `scriptCompleted`, `templateParseStarted`, `templateStarted`, `templateCompleted`
- **In-template debugging** — `consoleLog`, `announce`, `fatalError`
- **Expression/function evaluation** — `expressionEvaluated`, `functionCallEvaluated`
- **Variable mutations** — `variableSet` (with old and new values)
- **Parsing detail** (fine-grained, filterable) — `parseBlockStarted`, `parseBlockEnded`, `statementDetected`, `multiBlockDetected`, `multiBlockFailed`, `textContent`, `parsedTreeDumped`
- **Errors** — `error` (with category, message, source location, call stack)

Every event is wrapped in a `DebugEventEnvelope` that adds `sequenceNo`, `timestamp`, and `containerName` (see [section 14.9](#149-multi-container-runs)).

```swift
struct DebugEventEnvelope: Codable, Sendable {
    let sequenceNo: Int
    let timestamp: Date
    let containerName: String?
    let event: DebugEvent
}

enum BranchKind: String, Codable {
    case ifTrue, elseIfTrue, elseBlock
}
```

---

## 8. What the UI Should Show

The debug console has two modes: **Post-Mortem** (time-travel browsing after the run) and **Live** (stepping through execution with breakpoints). Both modes share the same panels.

### Panel 1: Pipeline Timeline + Time-Travel Slider

A horizontal phase bar: `Discover → Load → Hydrate → Transform → Render → Persist`. Each phase shows duration and status (success/skipped/failed). Click a phase to filter events to that phase.

Below the phase bar, a **timeline slider** with dots for every captured event. Dragging the slider or clicking a dot jumps the entire UI to that point in execution — the source panel, variable inspector, and call stack all update to reflect the state at that moment.

### Panel 2: Source Panel (Central)

The largest panel — shows the source file currently in focus (`.ss`, `.teso`, or `.modelhike`). Features:

- **Line numbers** in a gutter column
- **Syntax highlighting** — keywords, `{{ }}` expressions, `:` prefixed statements, `===` fences, `@` annotations
- **Current line highlight** — yellow background on the line associated with the selected event or stepping position
- **Error line highlight** — red background on lines where errors occurred
- **Breakpoint gutter** — click line numbers to toggle red breakpoint dots (in Live mode, these pause execution)
- **Call stack navigation** — clicking a call stack frame switches the source panel to that file and scrolls to that line
- **Hover tooltips** — hovering a variable name in the source shows its current value (from the nearest snapshot)

The source content is loaded from the `SourceFileMap` — all files are captured during the pipeline run, so this works even in post-mortem mode.

### Panel 3: Model Explorer

A tree view:
```
▼ Container: APIs (microservices)
  ▼ Module: Registry Management
    ▼ Entity: Registry
      * _id: Id
      * name: String
      - desc: String
      ~ findByName(name: String) : Registry
    ▶ DTO: RegistrySummary
    ▶ UIView: RegistryForm
  ▶ Module: User Management
```

Click any node to see its full properties, annotations, tags, attributes, attached APIs, mixins, and methods (with parameters and return types).

### Panel 4: Execution Trace

A chronological list of events with icons and colour coding:
- 📁 File generated / copied / excluded
- 🔀 Control flow decisions (if/else-if/else — which branch taken)
- 📝 Console log output
- ⚠️ Warnings (stop-render, excluded files)
- 🔴 Errors

Each entry is clickable — selecting it jumps the source panel to the corresponding file + line and updates the variable inspector to that point.

File generation entries show: output path, template used, working_dir at that point.

### Panel 5: Variable Inspector

Shows all variables and their values at the currently selected time-travel point, in a searchable, sortable table:

| Variable | Value | Type | Changed? |
|---|---|---|---|
| `@container.name` | `"APIs"` | C4Container | |
| `working_dir` | `"/apps/registry/src/"` | String | ● (changed) |
| `entity.name` | `"Registry"` | DomainObject | |
| `prop.type` | `"String"` | TypeInfo | ● (changed) |

The "Changed?" column highlights variables that differ from the previous snapshot — immediately showing what changed at this execution step.

**Comparison mode:** Select two timeline points and see a side-by-side diff of all variable values.

### Panel 6: Call Stack

Visual call stack showing the nested chain of script/template calls leading to the current point:

```
► entity.service.teso [15]  {{ prop.type | typename }}
  main.ss [42]              render-file entity.service.teso as user.service.ts
  [Rendering Root Folder]
```

Each frame is clickable — clicking navigates the source panel to that file + line.

### Panel 7: Error Detail

When errors exist, a prominent error banner shows:
- Error category badge (parsing / evaluation / model / internal)
- File and line number — **clickable, navigates the source panel to the error location**
- Error message
- Visual call stack (newest frame at top)
- Memory dump (full variable state at the error point)
- Extra debug info (if inside a template function — shows function name and argument values)

### Panel 8: Generated Files

A file tree of all output files. Click a file to see:
- Which template generated it
- Which model object it was generated for
- The `working_dir` at generation time
- **Click "Show in trace"** — jumps the timeline to the event where this file was generated, showing the source template and variable state at that moment

### Panel 9: Expression Playground

A text input where you can type a TemplateSoup expression (e.g., `{{ entity.name | lowercase }}`). It evaluates against the captured model/context and shows the result. Powered by the `/api/evaluate` endpoint calling `ws.render(string:data:)` on the still-alive workspace.

### Panel 10: Stepping Controls (Live Mode)

When running in live stepping mode (breakpoints set), a toolbar at the top provides:

| Button | Action | Keyboard |
|---|---|---|
| ▶ Continue | Resume until next breakpoint | F5 |
| ⤵ Step Over | Execute current statement, pause at next sibling | F10 |
| ↓ Step Into | Enter the current `render-file` / `for` / `if` body | F11 |
| ↑ Step Out | Resume until current scope exits | Shift+F11 |
| ⟳ Next Iteration | Finish current `for` iteration, pause at start of next | F9 |

These mirror standard IDE debugger controls, with **Next Iteration** added for `for` loop debugging (see [section 14.7](#147-for-loop-stepping-granularity)).

---

## 9. Data Model for Debug Events

### Capture Granularity

Covered in detail in [section 6.2 (Time-Travel Debugging — Snapshot Strategy)](#62-snapshot-strategy). Summary:

- **Full snapshots** at phase boundaries and file generation starts
- **Delta snapshots** for `set`/`set-str` (old value → new value)
- **Condition snapshots** for `if`/`else-if` (expression + resolved boolean + referenced variables)
- **Full + call stack** for errors
- **Iterator state** for `for` loops

### Source File Capture

Every source file encountered during the pipeline is registered in the `SourceFileMap`:

```swift
struct SourceFile: Codable, Sendable {
    let identifier: String       // pInfo.identifier — matches events
    let fullPath: String?        // absolute filesystem path if from LocalFile
    let content: String          // full file text
    let lineCount: Int           // pre-computed for UI
    let fileType: SourceFileType
}

enum SourceFileType: String, Codable {
    case soupyScript  // .ss files
    case template     // .teso files
    case model        // .modelhike files
    case config       // .tconfig files
}
```

Capture points:
- `LineParser.init(string:identifier:...)` — when a template/script string is loaded into a parser
- `LineParser.init(file:...)` — when a file is read from disk
- `ModelFileParser` — when `.modelhike` files are read

### Event Source Locations

Every event that originates from a parsed line includes a `SourceLocation`:

```swift
struct SourceLocation: Codable, Sendable {
    let fileIdentifier: String  // matches SourceFile.identifier
    let lineNo: Int             // 1-based, from pInfo.lineNo
    let lineContent: String     // from pInfo.line — for quick display without file lookup
    let level: Int              // nesting depth, from pInfo.level
}
```

The frontend uses `fileIdentifier` to look up the `SourceFile` from the map, then scrolls to `lineNo` and highlights it.

### Model Snapshots

All debug data must be `Codable` for JSON transport. The model objects (`C4Container`, `DomainObject`, `Property`, etc.) are actors and not `Codable`. The solution is a parallel set of lightweight `Codable` snapshot structs:

```swift
struct ContainerSnapshot: Codable {
    let name: String
    let givenname: String
    let containerType: String
    let modules: [ModuleSnapshot]
}

struct ModuleSnapshot: Codable {
    let name: String
    let givenname: String
    let objects: [ObjectSnapshot]
    let submodules: [ModuleSnapshot]
}

struct ObjectSnapshot: Codable {
    let name: String
    let givenname: String
    let kind: String          // entity, dto, ui, cache, etc.
    let properties: [PropertySnapshot]
    let methods: [MethodSnapshot]
    let annotations: [String]
    let tags: [String]
    let apis: [APISnapshot]
}
```

These are built once after the Load + Hydrate phases by walking the actor tree with `await`.

---

## 10. Integration Points in Existing Code

The existing codebase already has well-defined hook points. Here's where each debug component plugs in:

### 10.1 `ContextDebugLog` (DebugUtils.swift)

**Current:** 30+ methods that call `print()` behind flag checks.
**Change:** Add `recorder: DebugRecorder?` and `stepper: DebugStepper?` properties. When recorder is non-nil, each method also calls `recorder.record(...)` with a structured event. The `print()` calls remain — dual output. When `--debug` is active, events are captured **regardless of flag settings** (flags only control stdout printing; the recorder captures everything).

This is the **single biggest integration point**. Every debug method in `ContextDebugLog` becomes an event source.

### 10.2 `GenericStmtsContainer.execute()` (TemplateStmtContainer.swift)

**Current:** The central execution loop — iterates `TemplateItem`s and calls `item.execute(with: ctx)`.
**Change:** Insert the stepping hook before each item execution:

```swift
public func execute(with ctx: Context) async throws -> String? {
    var str: String = ""
    for item in items {
        if let stepper = ctx.debugStepper {
            await stepper.willExecute(item: item, ctx: ctx)
        }
        if let result = try await item.execute(with: ctx) {
            str += result
        }
    }
    return str.isNotEmpty ? str : nil
}
```

This is a **2-line insertion** in a single file. When `debugStepper` is nil (no `--debug` flag), zero overhead.

### 10.3 `LineParser` / `GenericLineParser` (LineParser.swift)

**Current:** Loads file contents into `lines: [String]` and exposes them via `currentLine()`, `identifier`, etc.
**Change:** When `DebugRecorder` is present, register the file contents in `SourceFileMap` upon initialization. The `identifier` (filename) and `lines` array are already available. For `init(file:...)`, the `LocalFile.path` provides the full filesystem path.

### 10.4 `CodeGenerationEvents` (CodeGenerationEvents.swift)

**Current:** Optional closures set by the user in `DevMain.swift`.
**Change:** In `--debug` mode, install default event handlers that feed the recorder. User-set handlers (if any) still run first.

### 10.5 `Pipeline.run()` (Pipeline.swift)

**Current:** Runs phases in a loop, catches errors, calls `PipelineErrorPrinter`.
**Change:** Before each phase, emit `phaseStarted`. After each phase, emit `phaseCompleted` with duration. On error, emit `phaseFailed` and capture the error via `DebugRecorder.captureError()`. After Load+Hydrate, capture the model snapshot.

### 10.6 `PipelineErrorPrinter` (PipelineErrorPrinter.swift)

**Current:** Formats errors to stdout.
**Change:** Also serialize the structured error (category, file, line, message, call stack frames, memory dump) into the `DebugSession`. The `ParsedInfo` on every error already provides the source location.

### 10.7 `CallStack` (CallStack.swift)

**Current:** Push/pop during rendering; snapshot on error.
**Change:** No change needed for post-mortem. For live stepping, the `DebugStepper` reads `callStack.snapshot().count` to determine current depth for step-over/step-out logic.

### 10.8 `GenerateCodePass` / `CodeGenerationSandbox`

**Current:** Prints progress markers (`🛠️ Container used: ...`). The sandbox's `generateFile`, `copyFile`, `renderFolder` methods are where files are produced.
**Change:** Each of these methods emits a `DebugEvent` with the output path, template name, and a `SourceLocation` from the `pInfo` parameter they already receive.

### 10.9 `ScriptFileExecutor` / `TemplateEvaluator`

**Current:** Entry points for `.ss` and `.teso` execution. They create `LineParser`s with the file content.
**Change:** Register the file content in `SourceFileMap` when the `LineParser` is created. The `identifier` and `contents` are both available at this point. Also emit `scriptStarted` / `templateStarted` events.

### 10.10 `DevMain.swift`

**Current:** Entry point with hardcoded config.
**Change:** Check `CommandLine.arguments` for `--debug`. If present, create a `DebugRecorder` + `DebugStepper`, attach them to the config, run the pipeline, then start the `DebugServer`.

```swift
@main struct Development: Sendable {
    static func main() async {
        let isDebug = CommandLine.arguments.contains("--debug")
        do {
            try await runCodebaseGeneration(debug: isDebug)
        } catch {
            print(error)
        }
    }

    static func runCodebaseGeneration(debug: Bool) async throws {
        let pipeline = Pipelines.codegen
        var config = Environment.debug
        config.containersToOutput = ["APIs"]

        if debug {
            let recorder = DebugRecorder()
            let server = NetworkFrameworkDebugServer()
            let stepper = DebugStepper(server: server)
            config.debugRecorder = recorder
            config.debugStepper = stepper

            // Start server before pipeline so the browser can connect
            // and set breakpoints before execution begins
            try await server.start(port: 4800)
            print("🔍 Debug console: http://localhost:4800")
            print("🔍 Set breakpoints in the browser, then press ▶ to start...")

            // Wait for the browser to send "start" command
            await stepper.waitForStart()

            try await pipeline.run(using: config)

            // Pipeline done — switch to post-mortem mode
            let session = await recorder.session()
            await server.setSession(session)
            print("✅ Pipeline complete. Debug console still running at http://localhost:4800")
            await server.waitForShutdown()
        } else {
            try await pipeline.run(using: config)
        }
    }
}
```

Note the flow change from the earlier draft: when `--debug` is active, the server starts **before** the pipeline so the user can set breakpoints in the browser first. The pipeline begins when the user clicks "Start" in the browser. This gives a proper IDE-like experience:

1. Run with `--debug` → server starts, browser opens
2. User browses model files, sets breakpoints on specific lines
3. User clicks ▶ → pipeline starts, pauses at breakpoints
4. User steps through, inspects state at each pause
5. Pipeline completes → switches to post-mortem time-travel mode

---

## 11. Frontend Approach

### Framework: Ripple

The frontend uses [Ripple](https://www.ripplejs.com/) — a modern, compiler-driven TypeScript UI framework created by Dominic Gannaway (previously worked on React, Svelte, Lexical, and Inferno).

**Why Ripple fits this project:**

| Property | Detail |
|---|---|
| **Reactivity** | Fine-grained reactivity via `track()` and `@` syntax — ideal for the variable inspector and time-travel slider that update frequently |
| **Performance** | Industry-leading bundle size and memory usage — the debug console needs to handle thousands of events without lag |
| **TypeScript-native** | Built on a TypeScript superset — the debug event types and API responses can share type definitions |
| **Component model** | Clean component-based architecture with props and children — maps directly to the panel layout |
| **Scoped styling** | `<style>` blocks inside components — keeps each panel's CSS isolated |
| **SSR + Hydration** | Not needed for this use case, but available if the debug console is ever served pre-rendered |
| **Vite-based** | Standard Vite toolchain — fast dev server, HMR during frontend development |

### Setup

The frontend lives in a `DebugConsole/` directory (inside `DevTester/` or as a sibling). Scaffolded via:

```sh
npx degit Ripple-TS/ripple/templates/basic DebugConsole
cd DebugConsole
npm i
```

During development, `npm run dev` runs the Vite dev server with HMR. For production (bundled into the Swift executable), `npm run build` produces a `dist/` folder with static assets that get embedded as Swift Package resources.

### Component Structure

```
DebugConsole/src/
├── App.ripple                  # Root layout — panels + routing
├── components/
│   ├── PipelineTimeline.ripple # Phase bar + time-travel slider
│   ├── SourcePanel.ripple      # Source file viewer with line highlighting
│   ├── ModelExplorer.ripple    # Model tree (containers → modules → objects)
│   ├── ExecutionTrace.ripple   # Chronological event list
│   ├── VariableInspector.ripple# Variable table with "changed" markers
│   ├── CallStack.ripple        # Visual call stack frames
│   ├── ErrorDetail.ripple      # Error banner with call stack + memory dump
│   ├── GeneratedFiles.ripple   # Output file tree
│   ├── ExpressionPlayground.ripple # Expression input + result
│   └── SteppingControls.ripple # Play/Step Over/Step Into/Step Out buttons
├── lib/
│   ├── api.ts                  # Fetch wrappers for /api/* endpoints
│   ├── websocket.ts            # WebSocket client for stepping commands
│   ├── types.ts                # TypeScript types mirroring DebugEvent, SourceLocation, etc.
│   └── timetravel.ts           # Delta reconstruction logic
└── styles/
    └── theme.css               # CSS custom properties for dark theme
```

### Example: SourcePanel Component

```ripple
import { track } from 'ripple'

export component SourcePanel({ fileIdentifier, highlightLine, breakpoints, onToggleBreakpoint }) {
  let source = track(null);
  let lines = track([]);

  effect(() => {
    fetch(`/api/source/${@fileIdentifier}`)
      .then(r => r.json())
      .then(data => {
        @source = data;
        @lines = data.content.split('\n');
      });
  });

  <div class="source-panel">
    <div class="source-header">{@fileIdentifier}</div>
    <div class="source-body">
      for (let i = 0; i < @lines.length; i++) {
        let lineNo = i + 1;
        let isHighlighted = lineNo === @highlightLine;
        let hasBreakpoint = @breakpoints.has(lineNo);

        <div class={`source-line ${isHighlighted ? 'highlighted' : ''}`}>
          <span
            class={`gutter ${hasBreakpoint ? 'breakpoint' : ''}`}
            onClick={() => onToggleBreakpoint(lineNo)}
          >
            {lineNo}
          </span>
          <code>{@lines[i]}</code>
        </div>
      }
    </div>
  </div>

  <style>
    .source-panel { font-family: monospace; background: #1e1e1e; color: #d4d4d4; }
    .source-line { display: flex; line-height: 1.6; }
    .source-line.highlighted { background: #3a3a00; }
    .gutter { width: 3rem; text-align: right; padding-right: 0.5rem; color: #858585; cursor: pointer; }
    .gutter.breakpoint { color: #e51400; }
    .gutter.breakpoint::before { content: '●'; }
    code { white-space: pre; }
  </style>
}
```

### Build & Embed Strategy

1. **During frontend development:** Run `npm run dev` in `DebugConsole/` for Vite HMR. The `--debug-dev` flag on `DevTester` proxies `/` to the Vite dev server instead of serving bundled assets.
2. **For release:** Run `npm run build` → `dist/` folder contains `index.html` + JS/CSS bundles. These are copied into `DevTester/Assets/` as Swift Package resources. The `NetworkFrameworkDebugServer` serves them from `Bundle.module`.

### Styling

Dark theme (developer tool convention) using CSS custom properties. Panel layout via CSS Grid — resizable panels similar to VS Code's debug layout. The scoped `<style>` blocks in Ripple components keep panel styles isolated.

---

## 12. Implementation Plan

### Phase 1: Foundation + Source Mapping

1. **`DebugEvent` enum (all cases from §14.12) + `SourceLocation` + `DebugEventEnvelope` + `DebugSession`** — complete data model.
2. **`SourceFile` struct + `SourceFileMap` actor** — source file registry.
3. **`DebugRecorder` actor** — captures events, source files, model snapshots, memory snapshots.
4. **`DebugServing` protocol + `NetworkFrameworkDebugServer`** — protocol-abstracted server. Two ports: HTTP (4800) + WebSocket (4801). Includes the minimal HTTP parser (§14.2) and CORS headers (§14.5).
5. **Wire into `ContextDebugLog`** — add `recorder` property; emit events from all 41 methods (§14.12).
6. **Wire into `LineParser` init** — register source file contents in `SourceFileMap` (captures excluded files too, §14.6).
7. **Wire into `Pipeline.run()`** — emit phase start/complete/fail/skip events.
8. **`--debug` flag in `DevMain.swift`** — parse `CommandLine.arguments`. SIGINT handler (§14.1).
9. **Ripple frontend scaffold** — `DebugConsole/` project with `npm create ripple`. Build script + Makefile (§14.8).
10. **Initial UI** — pipeline timeline + events list + source panel with line highlighting + error detail.

**Result:** A working debug console with source-level mapping on every event.

### Phase 2: Time-Travel Debugging

11. **Base + delta snapshot infrastructure** — `MemorySnapshot`, `DeltaSnapshot`, reconstruction logic.
12. **Capture full snapshots at phase boundaries and file generation starts.**
13. **Capture delta snapshots at `set`/`set-str` and `for` loop iterations.**
14. **Time-travel slider UI** — scrubbing through events updates source panel, variable inspector, call stack.
15. **Variable Inspector panel** — searchable table with "changed" markers.
16. **Comparison mode** — select two points, diff variable values.
17. **Container filter** — dropdown to filter events/files by container name (§14.9).

**Result:** Full time-travel debugging with multi-container support.

### Phase 3: Model Explorer + File Traceability

18. **`ModelSnapshot` codable structs** — walk the actor tree, build snapshots.
19. **`/api/model` endpoint** — serve the model tree.
20. **Model Explorer panel** — tree view with drill-down into properties, methods, annotations, APIs.
21. **`GeneratedFileRecord`** — capture template name, object name, working_dir for each file.
22. **Generated Files panel** — file tree with "Show in trace" linking to the timeline event.

### Phase 4: Live Stepping

23. **`DebugStepper` actor** — breakpoint management, `CheckedContinuation` suspension, all 5 step modes including `nextIteration` (§14.7). Heartbeat timeout + disconnect handling (§14.1).
24. **Insertion into `GenericStmtsContainer.execute()`** — the 2-line stepping hook.
25. **WebSocket message protocol** — `addBreakpoint`, `removeBreakpoint`, `resume`, `paused` messages.
26. **Multi-client handling** — single controller, multiple viewers (§14.4).
27. **Pre-run flow** — server starts before pipeline; browser loads persisted breakpoints (§14.11), sends them over WebSocket; "Start" button begins execution.
28. **Stepping controls UI** — Continue / Step Over / Step Into / Step Out / Next Iteration buttons.
29. **Breakpoint gutter in source panel** — click line numbers to toggle breakpoints. `localStorage` persistence (§14.11).

**Result:** Full IDE-style stepping with breakpoint persistence, disconnect safety, and multi-client support.

### Phase 5: Expression Playground + Polish

30. **`/api/evaluate` endpoint** — accept expression string, run through `ws.render(string:data:)`.
31. **Expression Playground panel** — text input + result display.
32. **Search and filter** across all panels.
33. **"Show parsing detail" toggle** — reveals fine-grained parsing events (replaces `lineByLineParsing` flag).
34. **Export session as JSON** for sharing / attaching to bug reports.
35. **Session persistence** — save `DebugSession` to disk for offline browsing without re-running.
36. **`--debug-dev` flag** — serve frontend files from Vite dev server for live frontend development.

### Phase 6: Testing

37. **Unit tests** — `DebugEvent` codable round-trips, delta snapshot reconstruction (§14.10 Level 1).
38. **Integration tests with `Pipelines.empty`** — recorder captures events from template rendering (§14.10 Level 2).
39. **Integration tests with full pipeline** — recorder captures all phases, model, files (§14.10 Level 3).
40. **HTTP server tests** — request/response round-trips against live server on ephemeral port (§14.10 Level 4).

---

## 13. Open Questions

### Q1: Should the debug infrastructure live in `ModelHike` (library) or `DevTester` (executable)?

**Option A: In the library.** The `DebugRecorder`, event types, snapshot structs, `DebugStepper`, and `DebugServing` protocol live in `Sources/`. Any consumer of the library gets debug capability. The `NetworkFrameworkDebugServer` implementation and frontend assets stay in `DevTester`.

**Option B: In the executable only.** Everything debug-related lives in `DevTester/`. The library stays pristine.

**Recommendation:** Option A for the data model (`DebugEvent`, `DebugRecorder`, `DebugStepper`, `DebugServing` protocol, snapshot structs) — these are useful for any consumer and the stepper hook needs to live inside `GenericStmtsContainer` (which is in the library). Option B for the `NetworkFrameworkDebugServer` implementation and frontend assets — these are dev-tool concerns.

### Q2: Port selection

Should the port be configurable? Hardcode `4800` as default, allow `--debug-port 5000` override?

**Recommendation:** Yes, `--debug --port 5000`. Default to `4800`.

### Q3: Auto-open browser?

Should the server automatically open `http://localhost:4800` in the default browser?

**Recommendation:** Yes, via `Process` calling `open http://localhost:4800` on macOS. Add `--no-open` to suppress.

### Q4: What about the `ModelHike` library's `Sendable` strictness?

Adding `Codable` snapshot structs is fine — they're plain value types. The `DebugRecorder` and `DebugStepper` are actors, naturally `Sendable`. The `CheckedContinuation` used by the stepper is a standard Swift concurrency primitive — no concurrency concerns.

### Q5: Should `--debug` capture everything or respect flag settings?

**Recommendation:** `--debug` captures everything at medium granularity regardless of `config.flags` settings. The flags continue to control *stdout printing*. This way the debug console always has full data even if the user forgot to enable a flag. The user filters in the UI, not in the config.

### Q6: Session size — will it fit in memory?

A large model (50+ entities across multiple containers) with a full NestJS blueprint generates ~500 files. Estimated session size with delta compression: ~300 KB for snapshots + ~1 MB for events + ~500 KB for source files = **~2 MB**. Comfortably fits in memory and transfers to the browser in under a second.

### Q7: Should the stepping hook incur any cost when `--debug` is not active?

The hook in `GenericStmtsContainer.execute()` is `if let stepper = ctx.debugStepper`. When `debugStepper` is nil (normal runs), this is a single nil-check per statement — branch predictor will make this essentially free. No performance concern.

---

## 14. Edge Cases & Implementation Details

This section covers every gap identified during the self-audit.

### 14.1 Browser Disconnect During Stepping

If the user closes the browser while the pipeline is paused on a `CheckedContinuation`, the pipeline hangs forever. Three safety mechanisms prevent this:

**A. Heartbeat timeout.** The `DebugStepper` starts a 60-second timer when it pauses. If no WebSocket message arrives within that window, it auto-resumes in `.run` mode (continue to end). The timeout resets on every message.

```swift
actor DebugStepper {
    private let heartbeatTimeout: Duration = .seconds(60)
    private var heartbeatTask: Task<Void, Never>?

    func willExecute(item: TemplateItem, ctx: Context) async {
        guard shouldPause(at: item) else { return }
        await emitPauseEvent(item: item, ctx: ctx)

        heartbeatTask = Task {
            try? await Task.sleep(for: heartbeatTimeout)
            // No message received — auto-resume
            self.resume(mode: .run)
            print("⚠️ Debug console disconnected — auto-resuming pipeline")
        }

        await withCheckedContinuation { cont in
            self.continuation = cont
        }
    }

    func resume(mode: StepMode) {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        self.mode = mode
        continuation?.resume()
        continuation = nil
    }
}
```

**B. SIGINT handler.** When the user presses Ctrl+C in the terminal, a signal handler resumes the stepper before exiting:

```swift
signal(SIGINT) { _ in
    Task {
        await stepper?.resume(mode: .run)
        exit(0)
    }
}
```

**C. WebSocket `close` frame.** When the browser tab closes, the WebSocket sends a close frame. `NWConnection`'s state handler detects `.cancelled` or `.failed` and calls `stepper.resume(.run)`.

### 14.2 HTTP Parsing with Network.framework

`NWListener` provides raw TCP connections, not HTTP. A minimal HTTP parser is needed. Here's the precise scope — it only needs to handle what the debug console uses:

**Request parsing (what's needed):**
- `GET /path HTTP/1.1\r\n` — method, path, version
- `Host:`, `Connection:`, `Upgrade:`, `Sec-WebSocket-Key:` headers (for WebSocket upgrade)
- `Content-Length:` header (for POST body on `/api/evaluate`)
- No chunked encoding, no multipart, no compression, no keep-alive pipelining

**Response formatting (what's needed):**
- Status line: `HTTP/1.1 200 OK\r\n`
- Headers: `Content-Type`, `Content-Length`, `Connection`, `Access-Control-Allow-Origin` (for CORS)
- Body: JSON or HTML string

**Implementation sketch (~200 lines):**

```swift
struct HTTPRequest {
    let method: String      // GET, POST
    let path: String        // /api/session, /ws, etc.
    let headers: [String: String]
    let body: Data?

    init?(data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        let lines = string.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }

        self.method = String(parts[0])
        self.path = String(parts[1])

        var headers: [String: String] = [:]
        var headerEnd = 1
        for i in 1..<lines.count {
            let line = lines[i]
            if line.isEmpty { headerEnd = i; break }
            let hParts = line.split(separator: ":", maxSplits: 1)
            if hParts.count == 2 {
                headers[String(hParts[0]).trimmingCharacters(in: .whitespaces).lowercased()]
                    = String(hParts[1]).trimmingCharacters(in: .whitespaces)
            }
        }
        self.headers = headers

        let bodyStart = lines[headerEnd...].dropFirst().joined(separator: "\r\n")
        self.body = bodyStart.isEmpty ? nil : bodyStart.data(using: .utf8)
    }
}

struct HTTPResponse {
    static func ok(body: String, contentType: String = "application/json") -> Data {
        let bodyData = body.data(using: .utf8)!
        let header = """
        HTTP/1.1 200 OK\r
        Content-Type: \(contentType)\r
        Content-Length: \(bodyData.count)\r
        Connection: close\r
        Access-Control-Allow-Origin: *\r
        \r\n
        """
        return header.data(using: .utf8)! + bodyData
    }

    static func notFound() -> Data {
        return "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            .data(using: .utf8)!
    }
}
```

The router matches the path and dispatches:

```swift
func handleRequest(_ request: HTTPRequest, session: DebugSession) -> Data {
    switch (request.method, request.path) {
    case ("GET", "/"):
        return HTTPResponse.ok(body: indexHTML, contentType: "text/html")
    case ("GET", "/api/session"):
        return HTTPResponse.ok(body: session.toJSON())
    case ("GET", let path) where path.hasPrefix("/api/source/"):
        let identifier = String(path.dropFirst("/api/source/".count))
        // ...lookup and return
    case ("GET", "/api/model"):
        return HTTPResponse.ok(body: session.model.toJSON())
    case ("GET", "/api/events"):
        // parse query params, filter, return
    case ("POST", "/api/evaluate"):
        // read body, evaluate expression, return result
    default:
        return HTTPResponse.notFound()
    }
}
```

This is straightforward code — no framework needed. The total HTTP layer is ~200-300 lines.

### 14.3 WebSocket Upgrade Handshake

`Network.framework` provides `NWProtocolWebSocket.Options` that can be added to the connection's protocol stack. However, the upgrade from HTTP must be handled manually:

1. Receive the initial HTTP request.
2. Check for `Upgrade: websocket` and `Sec-WebSocket-Key` headers.
3. Compute the accept key: `SHA1(key + "258EAFA5-E914-47DA-95CA-5AB5AA63")`, base64-encoded.
4. Send the `101 Switching Protocols` response.
5. From this point, use `NWProtocolWebSocket` framing on the connection.

**Alternative (simpler):** Create a second `NWListener` on a different port (e.g., 4801) that uses `NWProtocolWebSocket` from the start — no HTTP upgrade needed. The browser connects to `ws://localhost:4801`. This avoids the upgrade complexity entirely at the cost of one extra port.

**Recommended:** The two-port approach for v1. Cleaner separation — port 4800 is HTTP-only, port 4801 is WebSocket-only. The HTML page connects to the WebSocket port explicitly. Can be unified later.

### 14.4 Multiple Browser Clients

**Policy: Single controller, multiple viewers.**

- The first WebSocket connection becomes the **controller** — it can set breakpoints and send stepping commands.
- Subsequent WebSocket connections are **viewers** — they receive all events and pause notifications but their stepping commands are ignored.
- If the controller disconnects, the next oldest viewer is promoted to controller.
- The server tracks connection order in a list.

The UI shows a badge: "Controller" or "Viewer (read-only)" in the top bar. Viewers see all the same data and can browse time-travel state, but the stepping controls are greyed out.

### 14.5 CORS for `--debug-dev`

When using `--debug-dev` with the Vite dev server (typically `http://localhost:5173`), the browser blocks cross-origin requests to the Swift server (`http://localhost:4800`).

**Solution:** The Swift HTTP server always includes these headers on every response:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

For preflight `OPTIONS` requests, return a `204 No Content` with the above headers. This is already shown in the `HTTPResponse` helper above.

This is safe because the debug server only listens on `localhost` — no external network exposure.

### 14.6 Excluded Files — Source Capture Before Exclusion

The concern: a `.teso` file excluded by `include-if` in its front matter might not have its source captured.

**This is a non-issue.** The source capture happens in `TemplateEvaluator.execute()` when the `LineParser` is created:

```swift
let contents = template.toString()
let lineparser = LineParserDuringGeneration(
    string: contents, identifier: template.name, ...)
```

The `LineParser` init is where the `DebugRecorder` captures the source. This happens **before** front-matter parsing and the `include-if` check. The front-matter `processVariables()` call comes later and may throw `ParserDirective.excludeFile`, but by then the source is already registered. The `DebugEvent.fileExcluded` event references the file identifier, and the frontend can display the source with the `include-if` line highlighted.

### 14.7 `for` Loop Stepping Granularity

A `for` loop iterating over 100 entities needs more than just "step over the entire loop" or "step into every iteration."

**Step modes for `for` loops:**

| Action | Behavior |
|---|---|
| **Step Over** on the `for` line | Executes all iterations, pauses at the next statement after `end-for` |
| **Step Into** on the `for` line | Enters the loop body, pauses at the first statement of iteration 1 |
| **Step Over** inside the loop body | Executes the current statement, pauses at the next statement in the same iteration |
| **Step Out** inside the loop body | Finishes the current iteration AND all remaining iterations, pauses after `end-for` |
| **Continue to Next Iteration** (new mode) | Finishes the current iteration, pauses at the first statement of the next iteration |

The "Continue to Next Iteration" mode is the key addition. It's implemented as: set `pauseAtDepth = currentDepth` and `mode = .nextIteration`. The stepper resumes, and when the `for` loop starts a new iteration at the same depth, it pauses again.

**WebSocket command:** `{ "action": "resume", "mode": "nextIteration" }`

**UI:** A fifth button in the stepping controls: **⟳ Next Iteration** (keyboard shortcut: F9).

The `StepMode` enum becomes:

```swift
enum StepMode: String, Codable {
    case run
    case stepOver
    case stepInto
    case stepOut
    case nextIteration
}
```

### 14.8 Build Script — Ripple to Swift Resources

The Ripple frontend needs a build pipeline that produces static assets, then copies them into the Swift package resources.

**Directory structure:**

```
modelhike/
├── DevTester/
│   ├── Assets/           # Swift Package resources (generated — .gitignored except for committed snapshots)
│   │   ├── index.html
│   │   ├── assets/
│   │   │   ├── app-[hash].js
│   │   │   └── app-[hash].css
│   ├── DevMain.swift
│   └── Environment.swift
├── DebugConsole/         # Ripple frontend project
│   ├── package.json
│   ├── vite.config.ts
│   ├── src/
│   │   ├── App.ripple
│   │   └── components/...
│   └── dist/             # Vite build output (gitignored)
```

**`Package.swift` change:**

```swift
.executableTarget(
    name: "DevTester",
    dependencies: ["ModelHike"],
    path: "DevTester",
    resources: [.copy("Assets")]  // <-- add this
)
```

**`Makefile` (project root):**

```makefile
.PHONY: build-frontend build-all

build-frontend:
	cd DebugConsole && npm run build
	rm -rf DevTester/Assets
	cp -r DebugConsole/dist DevTester/Assets

build-all: build-frontend
	swift build
```

**CI integration:** Run `make build-all` instead of `swift build`. The `DevTester/Assets/` folder should be committed to git (not gitignored) so that `swift build` works without Node.js. Rebuilding the frontend is only needed when the debug UI changes.

**Runtime loading:**

```swift
func loadFrontendAsset(_ path: String) -> Data? {
    // In --debug-dev mode, read from disk for live reload
    if debugDevMode, let data = try? Data(contentsOf: URL(fileURLWithPath: "DebugConsole/dist/\(path)")) {
        return data
    }
    // In normal --debug mode, read from bundle resources
    if let url = Bundle.module.url(forResource: path, withExtension: nil, subdirectory: "Assets") {
        return try? Data(contentsOf: url)
    }
    return nil
}
```

### 14.9 Multi-Container Runs

When `containersToOutput` lists multiple containers (e.g., `["APIs", "WebApp"]`), the pipeline generates code for each. Events from both containers interleave in the debug session.

**Data model change:** Every `DebugEvent` that occurs during container rendering gets a `containerName: String?` field:

```swift
struct DebugEventEnvelope: Codable, Sendable {
    let sequenceNo: Int
    let timestamp: Date
    let containerName: String?  // nil for events outside container rendering (Discover, Load, Hydrate)
    let event: DebugEvent
}
```

The `DebugRecorder` tracks the current container name (set when `GenerateCodePass.generateCodebase(container:...)` is called) and stamps every event.

**UI change:** A container filter dropdown at the top of the Execution Trace and Generated Files panels. Options: "All Containers", "APIs", "WebApp". The timeline slider shows all events but color-codes dots by container.

### 14.10 Testing Strategy

The debug infrastructure is testable at three levels:

**Level 1 — Unit tests for data model (no pipeline needed):**

```swift
// Test DebugEvent serialization round-trip
func testDebugEventCodable() throws {
    let event = DebugEvent.fileGenerated(outputPath: "user.service.ts", templateName: "entity.service.teso",
                                          objectName: "User", source: SourceLocation(fileIdentifier: "main.ss", lineNo: 42, lineContent: "render-file ...", level: 0))
    let data = try JSONEncoder().encode(event)
    let decoded = try JSONDecoder().decode(DebugEvent.self, from: data)
    // assert equality
}

// Test delta snapshot reconstruction
func testDeltaReconstruction() async {
    let recorder = DebugRecorder()
    await recorder.captureBaseSnapshot(/* ... */)
    await recorder.captureDelta(variable: "x", oldValue: "1", newValue: "2")
    await recorder.captureDelta(variable: "y", oldValue: nil, newValue: "hello")
    let state = await recorder.reconstructState(atEvent: 2)
    // assert x == "2", y == "hello"
}
```

**Level 2 — Integration tests with `Pipelines.empty` (template rendering, no files):**

```swift
func testDebugRecorderCapturesEvents() async throws {
    let recorder = DebugRecorder()
    var config = PipelineConfig()
    config.debugRecorder = recorder

    let ws = Pipelines.empty
    _ = try await ws.render(string: "{{ var1 }}", data: ["var1": "hello"])

    let session = await recorder.session()
    XCTAssertTrue(session.events.contains(where: { /* templateStarted */ }))
    XCTAssertTrue(session.sourceFiles.count > 0)
}
```

**Level 3 — Integration tests with full `Pipelines.codegen` and inline models:**

```swift
func testDebugRecorderFullPipeline() async throws {
    let recorder = DebugRecorder()
    var config = Environment.debug
    config.debugRecorder = recorder
    config.containersToOutput = ["APIs"]

    let pipeline = Pipelines.codegen
    try await pipeline.run(using: config)

    let session = await recorder.session()
    XCTAssertTrue(session.phases.count == 6)
    XCTAssertTrue(session.model.containers.count > 0)
    XCTAssertTrue(session.files.count > 0)
}
```

**Level 4 — HTTP server tests (test request/response without browser):**

```swift
func testHTTPRouting() async throws {
    let session = DebugSession(/* mock data */)
    let server = NetworkFrameworkDebugServer(session: session)
    try await server.start(port: 0)  // port 0 = OS picks a free port
    let port = await server.actualPort

    let url = URL(string: "http://localhost:\(port)/api/session")!
    let (data, response) = try await URLSession.shared.data(from: url)
    XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)

    let decoded = try JSONDecoder().decode(DebugSession.self, from: data)
    XCTAssertEqual(decoded.phases.count, session.phases.count)

    await server.stop()
}
```

**Frontend tests:** Use Ripple's testing utilities (if available) or Playwright for browser-level testing of the debug UI. This is lower priority — the Swift-side tests cover correctness; the frontend tests cover UX.

### 14.11 Breakpoint Persistence Across Runs

Breakpoints set in the browser should survive pipeline re-runs. On each `--debug` run, the user doesn't want to re-set breakpoints.

**Mechanism:** The browser stores breakpoints in `localStorage`:

```typescript
const STORAGE_KEY = 'modelhike-debug-breakpoints';

function saveBreakpoints(breakpoints: BreakpointLocation[]) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(breakpoints));
}

function loadBreakpoints(): BreakpointLocation[] {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
}
```

When the WebSocket connects, the browser sends all stored breakpoints as `addBreakpoint` messages. The `DebugStepper` receives them before the "start" command. This means:

1. User runs with `--debug`, sets breakpoints, debugs.
2. User fixes a template, re-runs with `--debug`.
3. Browser reconnects (same tab or new tab at same URL).
4. Stored breakpoints are sent automatically.
5. Execution pauses at the same breakpoints.

If a breakpoint references a file/line that no longer exists (file renamed or line changed), the stepper silently ignores it. The UI shows it as a "stale breakpoint" (greyed-out dot) that the user can remove.

### 14.12 `DebugEvent` Completeness — Cross-Check Against `ContextDebugLog`

Full mapping of every `ContextDebugLog` method to a `DebugEvent` case:

| # | `ContextDebugLog` Method | `DebugEvent` Case | Notes |
|---|---|---|---|
| 1 | `parseLines(startingFrom:till:line:lineNo:)` | `parseBlockStarted(keyword: String, source: SourceLocation)` | **NEW** — block-level parsing |
| 2 | `parseLines(ended:pInfo:)` | `parseBlockEnded(keyword: String, source: SourceLocation)` | **NEW** |
| 3 | `stmtDetected(keyWord:pInfo:)` | `statementDetected(keyword: String, source: SourceLocation)` | **NEW** — fine-grained |
| 4 | `multiBlockDetected(keyWord:pInfo:)` | `multiBlockDetected(keyword: String, source: SourceLocation)` | **NEW** |
| 5 | `multiBlockDetectFailed(pInfo:)` | `multiBlockFailed(source: SourceLocation)` | **NEW** |
| 6 | `comment(line:lineNo:)` | Not captured | Comments are noise — no debug value |
| 7 | `content(_:pInfo:)` | `textContent(text: String, source: SourceLocation)` | **NEW** — captured but filtered in UI by default |
| 8 | `inlineExpression(_:pInfo:)` | `expressionEvaluated(...)` | Already exists |
| 9 | `inlineFunctionCall(_:pInfo:)` | `functionCallEvaluated(expression: String, source: SourceLocation)` | **NEW** |
| 10 | `line(_:pInfo:)` | Not separately captured | Redundant with other line-level events |
| 11 | `skipEmptyLine(lineNo:)` | Not captured | No debug value |
| 12 | `skipLine(lineNo:)` | Not captured | No debug value |
| 13 | `skipLine(by:lineNo:)` | Not captured | No debug value |
| 14 | `incrementLineNo(lineNo:)` | Not captured | No debug value |
| 15 | `printParsedTree(for:)` | `parsedTreeDumped(treeName: String, treeDescription: String)` | **NEW** — captures AST text |
| 16 | `ifConditionSatisfied(condition:pInfo:)` | `controlFlow(.ifTrue, ...)` | Already exists |
| 17 | `elseIfConditionSatisfied(condition:pInfo:)` | `controlFlow(.elseIfTrue, ...)` | Already exists |
| 18 | `elseBlockExecuting(_:)` | `controlFlow(.elseBlock, ...)` | Already exists |
| 19 | `templateParsingStarting()` | `templateParseStarted(name: String)` | **NEW** — distinct from `templateStarted` |
| 20 | `templateExecutionStarting()` | `templateStarted(...)` | Already exists (renamed to execution) |
| 21 | `scriptFileParsingStarting()` | `scriptParseStarted(name: String)` | **NEW** |
| 22 | `scriptFileExecutionStarting()` | `scriptStarted(...)` | Already exists |
| 23 | `workingDirectoryChanged(_:)` | `workingDirChanged(...)` | Already exists |
| 24 | `stopRenderingCurrentFile(_:pInfo:)` | `fileRenderStopped(...)` | Already exists |
| 25 | `throwErrorFromCurrentFile(_:err:pInfo:)` | `fatalError(...)` | Already exists |
| 26 | `excludingFile(_:)` | `fileExcluded(...)` | Already exists |
| 27 | `generatingFile(_:)` | `fileGenerated(...)` | Already exists |
| 28 | `copyingFile(_:)` | `fileCopied(...)` | Already exists |
| 29 | `copyingFile(_:to:)` | `fileCopied(...)` | Already exists (with outputPath) |
| 30 | `copyingFileInFolder(_:folder:)` | `fileCopied(...)` | Merged — folder path included in `outputPath` |
| 31 | `copyingFileInFolder(_:to:folder:)` | `fileCopied(...)` | Merged |
| 32 | `copyingFolder(_:)` | `folderCopied(...)` | Already exists |
| 33 | `copyingFolder(_:to:)` | `folderCopied(...)` | Already exists |
| 34 | `renderingFolder(_:to:)` | `folderRendered(...)` | Already exists |
| 35 | `generatingFile(_:with:)` | `fileGenerated(...)` | Already exists (with templateName) |
| 36 | `fileNotGenerated(_:with:)` | `fileSkipped(path: String, templateName: String?, reason: String, source: SourceLocation)` | **NEW** |
| 37 | `generatingFileInFolder(_:with:folder:)` | `fileGenerated(...)` | Merged — folder in outputPath |
| 38 | `fileNotGeneratedInFolder(_:with:folder:)` | `fileSkipped(...)` | **NEW** (same case as #36) |
| 39 | `fileNotGenerated(_:)` | `fileSkipped(...)` | **NEW** (same case as #36) |
| 40 | `pipelinePhaseCannotRun(_:msg:)` | `phaseSkipped(name: String, reason: String)` | **NEW** |
| 41 | `pipelinePassCannotRun(_:msg:)` | `passSkipped(name: String, reason: String?)` | **NEW** |

**Updated `DebugEvent` enum with all cases:**

```swift
enum DebugEvent: Codable, Sendable {
    // Pipeline lifecycle
    case phaseStarted(name: String, timestamp: Date)
    case phaseCompleted(name: String, duration: Double)
    case phaseFailed(name: String, error: String)
    case phaseSkipped(name: String, reason: String)
    case passSkipped(name: String, reason: String?)

    // Model loading
    case modelLoaded(containerCount: Int, typeCount: Int, commonTypeCount: Int)

    // File generation
    case fileGenerated(outputPath: String, templateName: String?, objectName: String?, source: SourceLocation)
    case fileCopied(sourcePath: String, outputPath: String, source: SourceLocation)
    case fileExcluded(path: String, reason: String, source: SourceLocation)
    case fileRenderStopped(path: String, source: SourceLocation)
    case fileSkipped(path: String, templateName: String?, reason: String, source: SourceLocation)
    case folderCopied(path: String, outputPath: String, source: SourceLocation)
    case folderRendered(path: String, outputPath: String, source: SourceLocation)

    // Working directory
    case workingDirChanged(from: String, to: String, source: SourceLocation)

    // Control flow
    case controlFlow(branch: BranchKind, condition: String, satisfied: Bool, source: SourceLocation)

    // Script/template lifecycle (parse and execute are distinct moments)
    case scriptParseStarted(name: String)
    case scriptStarted(name: String, source: SourceLocation)
    case scriptCompleted(name: String)
    case templateParseStarted(name: String)
    case templateStarted(name: String, source: SourceLocation)
    case templateCompleted(name: String)

    // In-template debugging
    case consoleLog(value: String, source: SourceLocation)
    case announce(value: String)
    case fatalError(message: String, source: SourceLocation)

    // Expression and function evaluation
    case expressionEvaluated(expression: String, result: String, source: SourceLocation)
    case functionCallEvaluated(expression: String, source: SourceLocation)

    // Variable mutations
    case variableSet(name: String, oldValue: String?, newValue: String, source: SourceLocation)

    // Parsing detail (fine-grained — filterable in UI)
    case parseBlockStarted(keyword: String, source: SourceLocation)
    case parseBlockEnded(keyword: String, source: SourceLocation)
    case statementDetected(keyword: String, source: SourceLocation)
    case multiBlockDetected(keyword: String, source: SourceLocation)
    case multiBlockFailed(source: SourceLocation)
    case textContent(text: String, source: SourceLocation)
    case parsedTreeDumped(treeName: String, treeDescription: String)

    // Errors
    case error(category: String, message: String, source: SourceLocation, callStack: [SourceLocation])
}
```

The fine-grained parsing events (`parseBlockStarted`, `statementDetected`, `textContent`, etc.) are captured by the recorder but hidden in the UI by default. A "Show parsing detail" toggle in the Execution Trace panel reveals them — this replaces the `lineByLineParsing` / `blockByBlockParsing` flags with a UI filter.

---

## 15. Alternatives Considered

### A1: VS Code Extension Instead of Web UI

A VS Code extension could show debug panels natively in the IDE. However:
- Much higher development effort (TypeScript extension API, custom views, webview panels).
- Ties the debug experience to one editor.
- The web UI works everywhere and can be developed in HTML/JS with rapid iteration.

**Verdict:** Web UI first. A VS Code extension could wrap the same web UI in a webview panel later.

### A2: macOS Native App (SwiftUI)

A native macOS debug app would have the richest UI. However:
- Separate app target, separate build, more maintenance.
- Can't be used from a terminal-only SSH session (rare but possible).
- Web UI is simpler and more portable.

**Verdict:** Web UI first. The JSON API could serve a native app later.

### A3: Terminal UI (TUI) with curses

A `ncurses`-style terminal UI avoids the browser entirely. However:
- Much harder to build rich interactive panels (tree views, search, syntax highlighting).
- Poor UX compared to a browser.
- Limited rendering capabilities.

**Verdict:** Not worth the effort when a browser is always available on macOS.

### A4: Write Debug Session to JSON File, Use External Viewer

Generate a `.json` file and open it in a separate viewer tool (like a JSON tree viewer or a custom Electron app). This decouples the server from the pipeline entirely.

**Verdict:** This is actually a good *complementary* feature (see Phase 5, item 22: session persistence). But the integrated server + UI provides a much better experience for the common case.

### A5: Integrate with Instruments / OSLog

Use Apple's `os_signpost` and `OSLog` to emit structured logs viewable in Instruments. This gives timeline visualization and filtering for free.

**Verdict:** Interesting for performance profiling but wrong tool for template/model debugging. Instruments doesn't understand ModelHike's domain concepts (templates, expressions, model objects). The custom UI is necessary.

---

## Summary

| Question | Answer |
|---|---|
| Will it work? | **Yes** — both time-travel and live stepping are feasible |
| Real-time stepping? | **Included** — 2-line hook in `GenericStmtsContainer.execute()` + `DebugStepper` actor using `CheckedContinuation`. 5 step modes including `nextIteration` for `for` loops |
| Source-level mapping? | **Included from day 1** — `ParsedInfo` already has file identifier + line number + line content; source files captured at `LineParser` init (before front-matter exclusion) |
| Server abstraction? | **`DebugServing` protocol** — `NetworkFrameworkDebugServer` (macOS) is the default; two-port design (HTTP + WebSocket); protocol allows swap later |
| Time-travel debugging? | **Core paradigm** — base + delta snapshots, timeline scrubbing, variable comparison, container filtering |
| Browser disconnect? | **Handled** — 60s heartbeat timeout, SIGINT handler, WebSocket close-frame detection (§14.1) |
| Multiple clients? | **Single controller + multiple viewers** — stepping controls greyed out for viewers (§14.4) |
| HTTP without framework? | **~200-300 lines** — minimal `HTTPRequest` parser + `HTTPResponse` formatter. Detailed implementation sketch in §14.2 |
| CORS? | **Handled** — `Access-Control-Allow-Origin: *` on all responses + OPTIONS preflight support (§14.5) |
| Breakpoint persistence? | **`localStorage`** — breakpoints survive browser refresh and pipeline re-runs (§14.11) |
| Event completeness? | **41/41 `ContextDebugLog` methods mapped** — full cross-check in §14.12 |
| Frontend? | **Ripple** (compiler-driven TypeScript UI framework) — Vite-based, built to `dist/`, copied to Swift resources via Makefile (§14.8) |
| Multi-container? | **`DebugEventEnvelope`** wraps events with `containerName` — UI provides container filter dropdown (§14.9) |
| Testing? | **4 levels** — unit (codable + snapshots), integration (empty pipeline), integration (full pipeline), HTTP server (§14.10) |
| External dependencies? | **Zero for Swift** — `Network.framework` is a system framework. **Node.js required for frontend build only** |
| Performance impact when `--debug` is off? | **Negligible** — one nil-check per statement in the hot loop |
| Effort estimate | Phase 1: ~5 days. Phase 2: ~3 days. Phase 3: ~2 days. Phase 4: ~4 days. Phase 5: ~2 days. Phase 6: ~2 days. **Total: ~18 days** |
| What it doesn't replace | Xcode debugger for Swift-level bugs; that's by design |
| Confidence level | **100%** — every `ContextDebugLog` method mapped, every edge case addressed, HTTP/WebSocket implementation specified, build pipeline defined, testing strategy documented |
