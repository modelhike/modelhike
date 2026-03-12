# Visual Debugging System

This document explains how the current ModelHike visual debugging system works, how its pieces fit together, and what is implemented versus scaffolded.

It describes the system as it exists today, not just the original brainstorm in `.ai/brainstorm/debug-console-brainstorm.md`.

## Purpose

The visual debugger replaces most ad-hoc `print()`-driven debugging with a structured, browser-based inspection flow for a pipeline run.

At a high level it provides:

- a `--debug` execution mode in `DevTester`
- a structured in-memory debug session
- a local HTTP server that exposes the session and related derived views
- a single-page browser UI for browsing phases, files, model snapshots, source, variables, and rendered outputs

The current system is primarily post-mortem:

- the pipeline runs to completion first
- debug data is captured during execution
- the browser UI is opened after the run

Live stepping support exists in the library as scaffolding, but `DevTester` currently installs a no-op stepper by default.

## Entry Point

The main entry point is `DevTester/DevMain.swift`.

When `DevTester` starts:

- if `--debug` is absent, it runs the normal code-generation flow
- if `--debug` is present, it runs `runCodebaseGenerationWithDebug()`

That debug path currently does this:

1. Builds `Pipelines.codegen`
2. Creates a `DefaultDebugRecorder`
3. Stores it on `config.debugRecorder`
4. Stores `NoOpDebugStepper()` on `config.debugStepper`
5. Runs the pipeline
6. Serializes the recorder state into a `DebugSession`
7. Extracts in-memory rendered output content from pipeline sandboxes
8. Starts `DebugHTTPServer`
9. Optionally opens the browser
10. Keeps the process alive until Ctrl+C

Relevant flags:

- `--debug`: enable debug mode
- `--debug-port=<port>`: choose the HTTP server port
- `--debug-dev`: serve `debug-console.html` directly from `DevTester/Assets`
- `--no-open`: do not auto-open the browser

## Runtime Architecture

The runtime is split into four layers.

### 1. Instrumented execution

The generator already has many hook points through `ContextDebugLog` in `Sources/Workspace/Context/DebugUtils.swift`.

These hooks are called from:

- template parsing and execution
- script parsing and execution
- file generation and copy operations
- control-flow decisions
- variable capture points
- error pathways

The system does not attach one giant tracer around the pipeline. Instead, instrumentation is distributed across the existing execution code paths.

### 2. Recorder and session model

`DefaultDebugRecorder` in `Sources/Debug/DebugRecorder.swift` is the central capture store.

It collects:

- `events`
- `sourceFiles`
- `generatedFiles`
- `baseSnapshots`
- `deltaSnapshots`
- `errors`
- `phaseRecords`
- `modelSnapshot`

At the end of the run it produces a `DebugSession`, defined in `Sources/Debug/DebugSession.swift`.

### 3. Local HTTP server

`DevTester/DebugServer/DebugHTTPServer.swift` serves the debug UI and JSON endpoints over `Network.framework`.

It is a small embedded HTTP server built around `NWListener` and `NWConnection`.

### 4. Browser UI

`DevTester/Assets/debug-console.html` is a self-contained HTML/CSS/JS app.

It fetches the captured session and derives most of its UI state client-side.

## Main Data Flow

The end-to-end data flow is:

```text
Pipeline execution
  -> ContextDebugLog emits debug events
  -> DefaultDebugRecorder stores events, sources, snapshots, errors, files
  -> Pipeline completes
  -> recorder.session(config:) produces DebugSession
  -> pipeline.state.renderedOutputRecords() extracts in-memory generated contents
  -> DebugHTTPServer serves both over HTTP
  -> debug-console.html fetches and renders them
```

There is no persistent debug database. Everything is in-memory for the lifetime of the `DevTester` process.

## Exact Integration Inventory

This section is intentionally file-oriented. It answers the question: "Where, exactly, does the visual debugger hook into the runtime?"

### `DevTester` layer

- `DevTester/DevMain.swift`
  - installs `DefaultDebugRecorder`
  - installs `NoOpDebugStepper`
  - runs the pipeline in debug mode
  - converts recorder state into `DebugSession`
  - extracts in-memory rendered outputs from retained sandboxes
  - starts `DebugHTTPServer`

- `DevTester/DebugServer/DebugHTTPServer.swift`
  - serves HTML
  - serves all JSON APIs
  - reconstructs variables through the recorder
  - evaluates expressions through the pipeline
  - resolves source identifiers heuristically
  - resolves generated output from in-memory `RenderedOutputRecord`s

- `DevTester/DebugServer/HTTPTypes.swift`
  - parses simple HTTP requests
  - builds all responses
  - injects no-cache headers to avoid stale console iterations in the browser

- `DevTester/Assets/debug-console.html`
  - derives UI state from `DebugSession`
  - builds file windows client-side
  - drives source/generated/variables/models panes
  - controls timeline/file-tree interaction

### Pipeline layer

- `Sources/Pipelines/Pipeline.swift`
  - records phase metadata through the recorder
  - retains generation sandboxes in `PipelineState`

- `Sources/Pipelines/PipelinePhase.swift`
  - `RenderPhase.runIn(pipeline:)` creates the sandbox that later becomes the source of in-memory rendered-output snapshots

- `Sources/Pipelines/PipelineConfig.swift`
  - carries `debugRecorder`
  - carries `debugStepper`

### Context and execution layer

- `Sources/Workspace/Context/Context.swift`
  - exposes `debugRecorder`
  - exposes `debugStepper`
  - exposes `variablesForDebug()`
  - carries `working_dir`

- `Sources/Workspace/Context/DebugUtils.swift`
  - central event emission adapter
  - records parser/runtime events
  - records file-generation metadata
  - captures base variable snapshots

- `Sources/Scripting/_Base_/TemplateStmtContainer.swift`
  - injects `debugStepper.willExecute(item:ctx:)` before every item executes

### Template/script parsing and execution layer

- `Sources/CodeGen/TemplateSoup/TemplateEvaluator.swift`
  - registers template source
  - emits template-parse and template-start events

- `Sources/Scripting/_Base_/ScriptFileExecutor.swift`
  - registers script source
  - emits script-parse and script-start events

- `Sources/Scripting/_Base_/Parsing/LineParser.swift`
  - emits line-level debug hooks such as line/skip/increment/end-of-block behavior

- `Sources/CodeGen/TemplateSoup/ContentLine/ContentHandler.swift`
  - emits `textContent`
  - emits inline-function-call events
  - emits inline-expression debug callbacks

- `Sources/Scripting/SoupyScript/ScriptParser.swift`
  - emits `statementDetected`

### Statement-level hook sites

- `Sources/Scripting/SoupyScript/Stmts/RenderFile.swift`
  - captures current variables
  - records `fileGenerated`
  - creates `GeneratedFileRecord`

- `Sources/Scripting/SoupyScript/Stmts/RenderFolder.swift`
  - emits rendered-folder events

- `Sources/Scripting/SoupyScript/Stmts/CopyFile.swift`
  - emits file-copy events

- `Sources/Scripting/SoupyScript/Stmts/CopyFolder.swift`
  - emits folder-copy events

- `Sources/Scripting/SoupyScript/Stmts/FillAndCopyFile.swift`
  - emits generated/skipped file events for placeholder-driven generation

- `Sources/Scripting/SoupyScript/Stmts/If.swift`
  - emits branch decisions

- `Sources/Scripting/SoupyScript/Stmts/SetVar.swift`
  - emits `workingDirChanged` when `working_dir` is updated

- `Sources/Scripting/SoupyScript/Stmts/SetStr.swift`
  - emits `workingDirChanged` when `working_dir` is updated

### Blueprint render/copy layer

- `Sources/CodeGen/TemplateSoup/_Base_/Blueprints/LocalFileBlueprint.swift`
  - emits generated/copied/skipped file events during local blueprint rendering

- `Sources/CodeGen/TemplateSoup/_Base_/Blueprints/ResourceBlueprint.swift`
  - emits generated/copied/skipped file events during resource blueprint rendering

### Snapshot and session layer

- `Sources/Debug/DebugRecorder.swift`
  - stores all recorder state
  - reconstructs variable state
  - serializes `DebugSession`

- `Sources/Debug/RenderedOutputSnapshot.swift`
  - walks retained `OutputFolder` trees and extracts in-memory rendered contents

## Core Data Types

### Debug events

`Sources/Debug/DebugEvent.swift`

`DebugEvent` is the main event enum. It includes:

- pipeline lifecycle events
- file generation and copy events
- working-directory changes
- control-flow decisions
- template and script lifecycle
- inline debugging output
- function/expression events
- variable mutation events
- parse-detail events
- error events

Each event is wrapped in `DebugEventEnvelope` from `Sources/Debug/DebugTypes.swift`, which adds:

- `sequenceNo`
- `timestamp`
- `containerName`

### Source mapping

`Sources/Debug/SourceFileMap.swift`

The visual debugger needs to show source files for templates and scripts. It therefore keeps a registry of source text in `SourceFileMap`.

Each `SourceFile` contains:

- `identifier`
- `fullPath`
- `content`
- `lineCount`
- `fileType`

Each event that can be source-linked may carry a `SourceLocation`:

- `fileIdentifier`
- `lineNo`
- `lineContent`
- `level`

### Debug session

`Sources/Debug/DebugSession.swift`

`DebugSession` is the JSON-serializable snapshot served to the browser. It contains:

- `timestamp`
- `config`
- `phases`
- `model`
- `events`
- `sourceFiles`
- `files`
- `errors`
- `baseSnapshots`
- `deltaSnapshots`

### Memory snapshots

`Sources/Debug/MemorySnapshot.swift`

The time-travel variable inspector is built from:

- `MemorySnapshot`
- `DeltaSnapshot`

`MemorySnapshot` stores:

- `label`
- `timestamp`
- `eventIndex`
- `variables`

`DeltaSnapshot` stores:

- `eventIndex`
- `variable`
- `oldValue`
- `newValue`

### Important structural note

The debug schema is larger than the currently emitted runtime behavior.

Some fields and event types are active in the implementation today; some exist as schema or scaffolding but are not yet wired through every runtime path.

## Event Index Semantics

`eventIndex` is currently stored as `Int`, and that is the correct type.

Why `Int` is correct:

- it is used as an index into Swift arrays
- the UI uses it directly against `session.events`
- the debug server exposes event-addressed APIs like `/api/memory/:eventIndex`

However, the semantics are subtle.

Current usage is not perfectly uniform:

- generated file records generally point at the actual event index of the generated-file event
- base snapshots are captured with `eventIndex: events.count`, which means "state valid after the first N events"

So today `eventIndex` should be read as a timeline coordinate, not always as "there is definitely an event stored exactly at this index with matching meaning".

This works, but it is a known conceptual sharp edge. If the system evolves further, it would be worth normalizing this so all `eventIndex` values follow one strict interpretation.

## Schema Versus Runtime Reality

The visual debugger has an important characteristic: the data model is ahead of the actual emitters.

That means `VISUALDEBUG.md` must distinguish between:

- schema that exists in types
- runtime behavior that is actually produced today

### Event cases currently defined but not fully or consistently emitted

The following `DebugEvent` cases exist in the schema but are not all actively emitted in the current runtime:

- `phaseStarted`
- `phaseCompleted`
- `phaseFailed`
- `modelLoaded`
- `scriptCompleted`
- `templateCompleted`
- `consoleLog`
- `announce`
- `expressionEvaluated`
- `variableSet`
- `error`
- `parseBlockStarted`

Some of these are effectively replaced by parallel data structures:

- phases are tracked in `session.phases`, not `session.events`

### Recorder capabilities that exist but are only partially wired

The recorder exposes more than the current runtime uses:

- `captureDelta(...)` exists, but delta capture is not broadly wired into variable mutation paths
- `captureError(...)` exists, but structured runtime error capture is not broadly wired into failure paths
- `setContainerName(...)` exists, but container name stamping is not actively set during the debug run

### Practical implication

A consumer of `DebugSession` should treat it as:

- reliable for emitted template/script/file/window browsing
- partially scaffolded for full time-travel and structured error forensics

## Event Emission Matrix

This section records what the current system actually emits, and where.

### Actively emitted today

- `templateParseStarted`
  - from `TemplateEvaluator`
- `templateStarted`
  - from `TemplateEvaluator`
- `scriptParseStarted`
  - from `ScriptFileExecutor`
- `scriptStarted`
  - from `ScriptFileExecutor`
- `statementDetected`
  - from `ScriptParser`
- `multiBlockDetected`
  - from `MultiBlockTemplateStmt+Config`
- `multiBlockFailed`
  - from `MultiBlockTemplateStmt+Config`
- `textContent`
  - from `ContentHandler`
- `functionCallEvaluated`
  - from `ContentHandler`
- `parsedTreeDumped`
  - from `ContextDebugLog.printParsedTree`
- `controlFlow`
  - from `If` statement execution paths
- `workingDirChanged`
  - from `SetVar` / `SetStr`
- `fileGenerated`
  - from `RenderFile`
  - from blueprint render-folder code paths
- `fileCopied`
  - from copy statements and blueprint copy paths
- `fileExcluded`
  - from parser-directive exclusion paths
- `fileRenderStopped`
  - from parser-directive stop-rendering paths
- `fileSkipped`
  - from "not generated" pathways
- `folderCopied`
  - from copy-folder paths
- `folderRendered`
  - from render-folder paths
- `fatalError`
  - from directive-driven error paths
- `passSkipped`
  - from pipeline phase/pass gating
- `phaseSkipped`
  - from pipeline phase gating

### Not emitted consistently today

- `phaseStarted`
- `phaseCompleted`
- `phaseFailed`
- `modelLoaded`
- `scriptCompleted`
- `templateCompleted`
- `consoleLog`
- `announce`
- `expressionEvaluated`
- `variableSet`
- `error`
- `parseBlockStarted`

## How Source Registration Works

Source registration happens at template and script load time.

### Templates

`Sources/CodeGen/TemplateSoup/TemplateEvaluator.swift`

Before a template is executed:

- its full contents are converted into a `SourceFile`
- that file is registered with the recorder
- the template is parsed with a `LineParserDuringGeneration`

The registered template identifier is `template.name`.

### Scripts

`Sources/Scripting/_Base_/ScriptFileExecutor.swift`

Before a script is executed:

- its full contents are converted into a `SourceFile`
- that file is registered with the recorder
- the script is parsed with a `LineParserDuringGeneration`

The registered script identifier is `scriptFile.name`.

### Source locations on events

Most event-producing helpers in `ContextDebugLog` derive source locations from `ParsedInfo` using:

```swift
SourceLocation(fileIdentifier: pInfo.identifier, lineNo: pInfo.lineNo, lineContent: pInfo.line, level: pInfo.level)
```

This is what makes line highlighting in the browser possible.

### Important limitations of source registration

The source registry is useful, but it is not perfect.

#### 1. Only templates and scripts are actively registered

Even though `SourceFileType` supports:

- `.soupyScript`
- `.template`
- `.model`
- `.config`

the current runtime actively registers only:

- template files
- script files

Model files and config files are not currently registered into the debug session by the active pipeline paths.

#### 2. `fullPath` is usually `nil`

Template and script source registration currently stores the source text, but not a stable filesystem path.

That means source lookup is keyed mostly by logical identifier, not physical path.

#### 3. Identifiers can collide

`SourceFileMap` is keyed by `identifier`.

If two distinct templates or scripts register with the same identifier, the later one overwrites the earlier one.

In practice this matters because many source lookups are name-driven, not path-driven.

## How File Generation is Tracked

File generation has two related but distinct representations.

### 1. Event stream

The event stream records things like:

- `fileGenerated`
- `fileCopied`
- `fileExcluded`
- `fileSkipped`

These are useful for timeline inspection.

### 2. Generated file records

`GeneratedFileRecord` stores file-centric metadata:

- `outputPath`
- `templateName`
- `objectName`
- `workingDir`
- `eventIndex`

This is what the browser uses to build the left file tree and per-file windows.

The important point is that the file tree is not inferred solely from raw events. It is driven by `session.files`.

### Rename caveat in blueprint-driven generation

There is an important edge case when a template file is rendered with an output filename different from the source filename.

In both blueprint implementations, the debug record can be emitted using the template-side `filename` while the actual output object uses a derived `outputFilename`.

That means a generated-file record can occasionally drift from the actual output filename for front-matter-driven rename flows.

This does not break all browsing behavior, but it is a real mismatch point to be aware of.

## How Variable Time-Travel Works

The visual variable inspector is reconstructed, not continuously streamed.

Mechanism:

1. A base snapshot is captured at specific points
2. Variable mutation deltas are recorded with their `eventIndex`
3. When the browser asks for `/api/memory/:eventIndex`, the recorder reconstructs state by:
   - choosing the latest base snapshot at or before the requested event index
   - applying all deltas up to that event index

This logic lives in `DefaultDebugRecorder.reconstructState(atEventIndex:)`.

Current trade-offs:

- compact and simple
- good enough for interactive inspection
- not a full replay engine
- depends on capture points being placed usefully

### Actual fidelity today

The current time-travel system is much weaker than the schema suggests.

What is true today:

- base snapshots are captured at selected points, especially around file generation
- many values are stringified before storage
- broad delta tracking is not currently wired through all variable writes

So the current variable inspector is best understood as:

- a useful, approximate time-sliced variable view
- not a full faithful replay of runtime object state

In particular, booleans, numbers, arrays, wrappers, and actor-backed objects are not preserved with full fidelity once they pass through the serialized debug snapshot path.

## Model Snapshot Capture

The UI does not traverse live actors directly.

Instead, after the pipeline has run, the recorder captures a flattened `ModelSnapshot` tree containing:

- containers
- modules
- objects
- properties
- methods
- annotations
- tags
- APIs

This is served as plain JSON and rendered in the `Models` tab.

## Rendered Output Internals

Originally, the bottom "Generated Output" pane tried to read files back from disk.

That was fragile because:

- path resolution varied between absolute and output-root-relative values
- some files were not easy to resolve from `workingDir`
- the debugger should really show what the pipeline rendered, not what the filesystem currently contains

The current implementation uses in-memory rendered output snapshots instead.

### Snapshot generation

`Sources/Debug/RenderedOutputSnapshot.swift`

After `pipeline.run(using:)` completes, `DevMain` calls:

```swift
await pipeline.state.renderedOutputRecords()
```

That walks every retained generation sandbox and recursively traverses `base_generation_dir`.

It extracts rendered content from supported output file types:

- `TemplateRenderedFile`
- `StaticFile`
- `PlaceHolderFile`
- `OutputDocumentFile`

Each result is stored as `RenderedOutputRecord(path:content:)`.

### Why this is better

- it reflects the exact in-memory rendered content
- it is independent of later filesystem mutations
- it avoids path resolution bugs for many generated artifacts

### Supported output file types

The current snapshot extraction supports these output object types:

- `TemplateRenderedFile`
- `StaticFile`
- `PlaceHolderFile`
- `OutputDocumentFile`

If a future output file type stores content differently and is not added to `RenderedOutputSnapshot.swift`, it will not appear in the generated-output pane.

## Pipeline and Sandbox Relationship

The pipeline retains generation sandboxes in `PipelineState`.

Relevant pieces:

- `Pipeline.state.generationSandboxes`
- `RenderPhase.runIn(pipeline:)` creates a sandbox and appends it to pipeline state
- each `CodeGenerationSandbox` owns an `OutputFolder` tree rooted at `base_generation_dir`

This retained sandbox state is what enables the rendered-output snapshot extraction after the run.

### Why sandbox retention matters

Without retained generation sandboxes:

- the browser would have to reread the filesystem
- rendered output could diverge from what was actually rendered in memory
- generated-output debugging would become sensitive to persistence order and post-run mutations

The retained sandbox model is therefore not incidental. It is central to the current "rendered output from memory" design.

## Debug HTTP Server

`DevTester/DebugServer/DebugHTTPServer.swift`

The debug server is intentionally small and local-only.

### Transport

- `NWListener` accepts TCP connections
- `NWConnection` reads one request, writes one response, then closes
- requests are parsed by `HTTPRequest` in `HTTPTypes.swift`
- responses are built by `HTTPResponse`

One important consequence:

- the `/ws` route only performs an upgrade handshake right now
- there is no persistent WebSocket session management loop in the current server

### HTTP caching policy

Responses include:

- `Cache-Control: no-store, no-cache, must-revalidate, max-age=0`
- `Pragma: no-cache`
- `Expires: 0`

This was added specifically because stale browser caches were causing the user to see old HTML and old API payloads after rapid debug-console iterations.

### Implemented endpoints

- `GET /`
  - serves `debug-console.html`
- `GET /api/session`
  - serves full `DebugSession`
- `GET /api/model`
  - serves `session.model`
- `GET /api/events`
  - serves `session.events`
- `GET /api/files`
  - serves `session.files`
- `GET /api/memory/:eventIndex`
  - reconstructs variable state
- `GET /api/source/:identifier`
  - serves registered source file contents
- `GET /api/generated-file/:index`
  - serves rendered generated-file content from in-memory snapshots
- `POST /api/evaluate`
  - evaluates an expression against reconstructed variables using `pipeline.render`
- `GET /ws`
  - performs WebSocket upgrade handshake only

### Exposed versus actively consumed endpoints

The server exposes more routes than the browser currently consumes.

Exposed:

- `/api/session`
- `/api/model`
- `/api/events`
- `/api/files`
- `/api/memory/:eventIndex`
- `/api/source/:identifier`
- `/api/generated-file/:index`
- `/api/evaluate`

Actively consumed by `debug-console.html`:

- `/api/session`
- `/api/memory/:eventIndex`
- `/api/source/:identifier`
- `/api/generated-file/:index`
- `/api/evaluate`

Currently unused by the browser UI:

- `/api/model`
- `/api/events`
- `/api/files`

### Security and scope note

This server is a development utility, not a hardened debug service.

Current properties:

- no authentication
- permissive `Access-Control-Allow-Origin: *`
- simple local dev transport
- intended for short-lived local inspection

It should be treated as a developer-only local tool.

### Source lookup behavior

The source lookup path currently tries multiple strategies:

- exact identifier match
- slash-normalized match
- suffix/prefix match for nested identifiers
- extension-aware fallback for `.teso` and `.ss`

This exists because generated file records may refer to template names like:

- `graphql-schema-module`
- `plantuml.classes`
- `List{{entity.name | plural}}Query.java`

while registered source identifiers may include different suffixes or path forms.

### Source lookup heuristics are deliberate

The current source lookup logic is heuristic because identifier capture is not normalized everywhere.

The heuristics are compensating for real mismatches in:

- suffixes
- relative versus nested identifiers
- extensionless template references
- template names that themselves contain render expressions

## Browser UI Internals

`DevTester/Assets/debug-console.html`

The UI is a single-file SPA with no framework dependency.

### Initial load

On load it:

1. fetches `/api/session`
2. stores it in `state.session`
3. derives `state.fileWindows` from `session.files`
4. renders the whole UI

The UI is intentionally thin:

- it keeps most heavy data shaping client-side
- it uses the full session payload as its primary state source
- it lazily refetches only dynamic panes such as variables, source text, and rendered output

### Main client-side state

Important fields:

- `session`
- `selectedIndex`
- `fileWindows`
- `activeSidebarTab`
- `renderToken`
- `fileTreeFilterIndex`
- `lastVisibleFileCount`

`renderToken` is especially important:

- source-pane and generated-output requests use it to ignore stale async responses after rapid selection changes

The variable inspector does not currently use this same guard.

### File windows

The UI groups events by generated file using `session.files`.

For each generated file record, it computes:

- `startIndex`
- `endIndex`
- `eventCount`
- `controlFlowCount`
- `templateCount`

This lets the UI show a per-file event window instead of dumping all session events at once.

### Window attribution caveat

File windows are contiguous timeline slices bounded by generated-file records.

This is pragmatic, but it means:

- any event between file A's generation point and file B's generation point is attributed to file A's window
- this is timeline grouping, not perfect semantic ownership

### Left sidebar behavior

The left sidebar is the generated-files tree.

Current behavior:

- the visible tree is filtered by `fileTreeFilterIndex`
- `fileTreeFilterIndex` changes only when the timeline slider is dragged
- clicking a file changes `selectedIndex`, but does not re-filter the tree

This was introduced so file clicks do not cause later files to disappear from the tree.

Additional behavior:

- folder rows toggle collapse/expand
- file rows force the right sidebar back to `Trace`
- the tree is reconstructed on each render
- when the visible file count shrinks, the files sidebar scroll is reset to the top

### Left sidebar caveats

- folder expansion state is not preserved across rerenders
- the filter boundary can differ from the current selected event because only slider movement updates `fileTreeFilterIndex`
- the tree is derived from `session.files`, not from the raw event stream

### Source pane behavior

The top center pane shows template or script source.

Source resolution prefers:

1. `currentWindow.templateName`
2. event-derived `SourceLocation.fileIdentifier`

If a usable location is found, the UI requests `/api/source/:identifier` and highlights the relevant line when possible.

Important nuance:

- the source pane may prefer the current file window's template name over the currently selected event's actual source file
- this is useful for file-centric browsing, but it means the pane is not always a literal event-source viewer

### Generated output pane behavior

The bottom center pane requests `/api/generated-file/:index`.

It no longer depends on reading files from disk.

The server-side payload currently includes:

- original path from `GeneratedFileRecord`
- resolved in-memory rendered path
- full content
- line count

### Variables tab

The variables inspector fetches `/api/memory/:eventIndex` and renders the reconstructed variable map in a simple table.

Current limitations:

- values are flattened to strings in many cases
- there is no nested object viewer
- there is no diff view against prior events
- there is no `renderToken` guard against stale variable responses after rapid scrubbing

### Models tab

The models tab renders the flattened `ModelSnapshot` hierarchy from the session payload.

Backend snapshot data includes more than the UI currently shows:

- annotations
- tags
- APIs

The current browser tree focuses on:

- containers
- modules
- objects
- properties
- methods

## Live Stepping Status

Live stepping is partially implemented in the library but not fully enabled in `DevTester`.

### What exists

- `DebugStepper` protocol
- `LiveDebugStepper`
- breakpoint representation
- pause callback
- continuation-based suspension logic
- execution-loop integration in `GenericStmtsContainer.execute(with:)`

That means the execution loop already calls:

```swift
if let stepper = await ctx.debugStepper {
    await stepper.willExecute(item: item, ctx: ctx)
}
```

### What is not enabled by default

`DevMain` currently sets:

```swift
config.debugStepper = NoOpDebugStepper()
```

So the current shipped `--debug` experience is post-mortem only.

### What is still missing for true live stepping

- the server starting before or during execution
- a real WebSocket message loop beyond handshake
- browser-to-stepper resume commands
- breakpoint management API
- a UI that can drive paused execution

So the stepping architecture is scaffolded, but not yet an active user-facing feature.

### Additional implementation caveats

`LiveDebugStepper` is not just disabled by default; its stepping semantics are also incomplete.

Current state:

- it stores `mode`
- it supports breakpoint sets
- it exposes `setOnPause`
- it suspends on exact file+line breakpoint matches

But today:

- `mode` is not used to implement true `stepOver`/`stepInto`/`stepOut`
- `setOnPause` is not wired into a server/browser control loop
- the browser has no active WebSocket client logic to drive resume commands

## Tests

There is test coverage for the core data model and recorder behavior:

- `Tests/Debug/DebugRecorder_Tests.swift`
- `Tests/Debug/DebugSession_Tests.swift`
- `Tests/Debug/ModelSnapshot_Tests.swift`

Current test coverage verifies:

- event recording and state reconstruction
- debug session Codable behavior
- model snapshot structure and JSON encoding

Current notable gap:

- there are no tests for the HTTP server
- there are no tests for the browser UI
- there are no end-to-end tests for source lookup or generated-output panes
- there are no tests for rendered-output snapshot extraction
- there are no tests for source-identifier heuristic matching
- there are no tests for live stepping behavior

## Current Limitations

### Post-mortem by default

The system is not yet a fully live debugger. It is a run-capture-browse debugger.

### Session is process-local

There is no session persistence across runs. Restarting `DevTester` creates a new in-memory session.

### Event-index semantics are slightly mixed

As described earlier, `eventIndex` is correct as `Int`, but its meaning is not perfectly normalized across all snapshot-producing paths.

### Source matching is heuristic in places

Source lookup currently uses normalization and extension-aware fallback. This is practical, but it means file-template naming conventions still matter.

### Source registration is incomplete

Model and config source files are not currently part of the active source-registration path, even though the schema supports them.

### Error capture is only partially structured

The schema supports structured errors, but many actual runtime failures are still surfaced primarily through pipeline error printing rather than `session.errors`.

### Event ordering is not fully synchronized

Some debug recorder writes are intentionally fire-and-forget `Task` calls. That keeps instrumentation lightweight, but it means strict ordering and flush guarantees are weaker than they would be with fully awaited recording.

### WebSocket support is incomplete

The server can respond to upgrade requests, but there is no complete live stepping message protocol currently exposed.

### Source-file identity can collide

Because `SourceFileMap` is keyed by identifier and source files are often registered with `fullPath: nil`, same-named files can overwrite one another.

## Troubleshooting

### The UI looks stale after changes

Possible causes:

- an older debug server is still running on the same port
- the browser cached old HTML or old API responses

Mitigations already in place:

- `--debug-dev` serves the HTML directly from `DevTester/Assets`
- HTTP responses now use `no-store` cache headers

Recommended workflow during development:

1. stop stale `DevTester` processes
2. run a fresh `swift run DevTester --debug --debug-dev --no-open`
3. reopen the URL

### "Source not found"

Check these first:

- is the file coming from a template or script that was registered as a source file
- does the generated file record have a meaningful `templateName`
- does the source identifier require `.teso` or `.ss` extension-aware fallback
- are multiple same-named templates/scripts colliding in the source registry

### Generated output missing

Today the generated output endpoint serves from in-memory rendered snapshots, not disk. If this fails, the likely issue is that the relevant output file type was not included in `RenderedOutputSnapshot.swift`.

## Extension Points

If this system is extended further, the most natural next steps are:

- normalize `eventIndex` semantics
- add HTTP/API tests
- add a real live stepping server loop
- normalize source-file identity around stable full paths instead of name heuristics
- wire model/config source registration into the active debug session
- wire structured error capture into failure paths
- wire variable deltas into actual mutation sites
- preserve UI pane sizes and active tabs in local storage
- expose event filtering controls in the UI
- add explicit source-path metadata instead of relying heavily on matching heuristics

## File Map

Important current files:

- `DevTester/DevMain.swift`
- `DevTester/DebugServer/DebugHTTPServer.swift`
- `DevTester/DebugServer/HTTPTypes.swift`
- `DevTester/Assets/debug-console.html`
- `Sources/Debug/DebugRecorder.swift`
- `Sources/Debug/DebugSession.swift`
- `Sources/Debug/DebugEvent.swift`
- `Sources/Debug/MemorySnapshot.swift`
- `Sources/Debug/SourceFileMap.swift`
- `Sources/Debug/RenderedOutputSnapshot.swift`
- `Sources/Debug/DebugStepper.swift`
- `Sources/Debug/LiveDebugStepper.swift`
- `Sources/Debug/NoOpDebugStepper.swift`
- `Sources/Workspace/Context/DebugUtils.swift`
- `Sources/CodeGen/TemplateSoup/TemplateEvaluator.swift`
- `Sources/Scripting/_Base_/ScriptFileExecutor.swift`
- `Sources/Scripting/_Base_/TemplateStmtContainer.swift`
- `Sources/Pipelines/Pipeline.swift`
- `Sources/Pipelines/PipelinePhase.swift`
- `Sources/Pipelines/PipelineConfig.swift`
- `Sources/Workspace/Context/Context.swift`
- `Sources/Workspace/Sandbox/CodeGenerationSandbox.swift`
- `Sources/CodeGen/TemplateSoup/_Base_/Blueprints/LocalFileBlueprint.swift`
- `Sources/CodeGen/TemplateSoup/_Base_/Blueprints/ResourceBlueprint.swift`
- `Sources/Scripting/SoupyScript/Stmts/RenderFile.swift`
- `Sources/Scripting/SoupyScript/Stmts/RenderFolder.swift`
- `Sources/Scripting/SoupyScript/Stmts/CopyFile.swift`
- `Sources/Scripting/SoupyScript/Stmts/CopyFolder.swift`
- `Sources/Scripting/SoupyScript/Stmts/FillAndCopyFile.swift`
- `Sources/Scripting/SoupyScript/Stmts/If.swift`
- `Sources/Scripting/SoupyScript/Stmts/SetVar.swift`
- `Sources/Scripting/SoupyScript/Stmts/SetStr.swift`
- `Sources/Scripting/_Base_/Parsing/LineParser.swift`
- `Sources/CodeGen/TemplateSoup/ContentLine/ContentHandler.swift`
- `Sources/Scripting/SoupyScript/ScriptParser.swift`

## Summary

The current visual debugging system is a structured post-run debugger layered onto the existing ModelHike execution model.

Its most important design choices are:

- capture debug data as structured events instead of relying on stdout
- snapshot source text so template/script source can be shown in the browser
- reconstruct variable state from base snapshots, with delta support scaffolded but not yet broadly wired
- derive file-centric browsing views from `GeneratedFileRecord`
- serve rendered outputs from the in-memory output tree instead of disk
- keep live stepping scaffolded but disabled by default
- expose a schema that is slightly ahead of the currently emitted runtime behavior

That makes it already useful as a practical debugging console, even though the fully interactive breakpoint-driven debugger is not yet fully turned on.
