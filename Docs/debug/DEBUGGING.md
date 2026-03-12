# ModelHike — Debugging Guide

When the pipeline doesn't produce the output you expect, ModelHike provides several layers of debug tooling. This guide covers every mechanism available, from quick flags to targeted event hooks to in-template logging.

---

## Table of Contents

1. [Quick Reference](#1-quick-reference)
2. [Always-On Pipeline Output](#2-always-on-pipeline-output)
3. [Debug Flags (`ContextDebugFlags`)](#3-debug-flags-contextdebugflags)
4. [Event Hooks (`CodeGenerationEvents`)](#4-event-hooks-codegenerationevents)
5. [Error Output Options](#5-error-output-options)
6. [In-Template Debugging (SoupyScript)](#6-in-template-debugging-soupyscript)
7. [Front-Matter Directives & File Exclusion](#7-front-matter-directives--file-exclusion)
8. [Error Reporting & Call Stack](#8-error-reporting--call-stack)
9. [Isolating a Single File or Object](#9-isolating-a-single-file-or-object)
10. [Isolating with `runTemplateStr()`](#10-isolating-with-runtemplatestr)
11. [Isolating with Inline Models](#11-isolating-with-inline-models)
12. [Scoping the Run with `containersToOutput`](#12-scoping-the-run-with-containerstooutput)
13. [Using the Xcode Debugger](#13-using-the-xcode-debugger)
14. [Common Debugging Scenarios](#14-common-debugging-scenarios)
15. [Blueprint-Specific Debugging Patterns](#15-blueprint-specific-debugging-patterns)

---

## 1. Quick Reference

All debugging is configured on the `config` object (`OutputConfig`) before calling `pipeline.run(using: config)`. The three main surfaces are:

| Surface | Access | Purpose |
|---|---|---|
| `config.flags` | `ContextDebugFlags` struct | Toggle categories of log output |
| `config.events` | `CodeGenerationEvents` actor | Intercept specific pipeline moments with closures |
| `config.errorOutput` | `ErrorOutputOptions` struct | Control what's included in error reports |

These are set in `DevMain.swift` between creating the config and calling `pipeline.run()`.

Beyond configuration, you also have:

| Tool | Where | Purpose |
|---|---|---|
| `console-log` / `announce` | Inside `.ss` / `.teso` files | Print variable values at runtime |
| `fatal-error` / `stop-render` | Inside `.ss` / `.teso` files | Halt execution for assertions or conditional exclusion |
| Front-matter `include-if` | `.teso` file header | Conditionally exclude entire files |
| `runTemplateStr()` | `DevMain.swift` | Test expressions in isolation outside the full pipeline |
| Inline models | `DevMain.swift` | Define a minimal model in Swift code to isolate parsing |
| Xcode breakpoints | Xcode debugger | Step through Swift code when all else fails |

---

## 2. Always-On Pipeline Output

Even without enabling any debug flags, the pipeline prints progress markers at key moments. These always appear in stdout:

| Message | Phase | Meaning |
|---|---|---|
| `❌❌ No Model Files Found!!!` | Discover | No `.modelhike` files found at `basePath` |
| `💡 Loaded domain types: N, common types: M` | Load | Models parsed successfully; shows type counts |
| `❌❌ No Model Found!!!` | Load | Files found but no parseable types inside them |
| `❌❌ ERROR IN LOADING MODELS ❌❌` | Load | Model parsing threw an error (detailed error follows) |
| `ℹ️ Loaded N blueprint modifier(s) from _modifiers_/` | Render | Blueprint-defined modifiers were found and registered |
| `⚠️ Didn't find 'Root' folder in Blueprint !!!` | Render | The blueprint has no `_root_/` folder (may be intentional) |
| `🛠️ Container used: <name>` | Render | Which container is being generated |
| `🛠️ Output folder: <path>` | Render | Where output files will be written |
| `✅ Generated N files, M folders ...` | Persist | Final count of generated output |
| `❌❌ ERROR OCCURRED IN <Phase> Phase ❌❌` | Any | Which phase threw the error |
| `❌❌❌ TERMINATED DUE TO ERROR ❌❌❌` | Any | Pipeline halted |

If you see `💡 Loaded domain types: 0` or unexpectedly low counts, the model files likely have syntax issues. If you see `✅ Generated 0 files`, the render phase ran but produced nothing — check `working_dir` and blueprint structure.

---

## 3. Debug Flags (`ContextDebugFlags`)

Flags are simple booleans on `config.flags`. Set them before the pipeline runs. Each one activates a category of `print()` output via `ContextDebugLog`.

```swift
var config = Environment.debug
config.flags.fileGeneration = true      // see every file being generated
config.flags.lineByLineParsing = true   // see every line parsed/executed in templates
try await pipeline.run(using: config)
```

### Available Flags

| Flag | Default | What It Logs |
|---|---|---|
| `fileGeneration` | `false` | Every file generated, copied, or skipped. Includes template name and output path. Also logs folder copies and renders. |
| `lineByLineParsing` | `false` | Every line processed during template/script parsing and execution: text content, `{{ }}` expressions, inline function calls, statement detection, block boundaries, if/else-if/else control flow, and parse-phase start/end banners. The most verbose flag. |
| `blockByBlockParsing` | `false` | A subset of `lineByLineParsing` — logs block-level structure (multiblock detect, parse-lines start/end, if/else-if/else flow, parse/execute banners) without individual line noise. |
| `controlFlow` | `false` | Logs only if/else-if/else branch decisions. The lightest way to trace conditional logic. |
| `printParsedTree` | `false` | After parsing a script/template, dumps the full parsed AST (`SoupyScriptStmtContainerList.debugDescription`). Useful when the parse succeeds but execution behaves unexpectedly. |
| `changesInWorkingDirectory` | `false` | Logs whenever `working_dir` changes, showing the new path. Helps trace where output files are being routed. |
| `excludedFiles` | `false` | Logs files excluded by front-matter `include-if` / `include-for` directives. |
| `renderingStoppedInFiles` | `false` | Logs when a `stop-render` statement halts rendering of a template. |
| `errorThrownInFiles` | `false` | Logs when a `fatal-error` statement fires inside a template. |
| `onSkipLines` | `false` | Logs skipped/empty lines during parsing. Very noisy; rarely needed. |
| `onIncrementLines` | `false` | Logs every line-number increment during parsing. Extremely noisy; only useful for parser-level debugging. |
| `onCommentedLines` | `false` | Logs commented lines (`//` lines) encountered during template/script parsing, printing `[lineNo] <line>`. |

### How Flags Interact

- `lineByLineParsing` is the superset — it activates everything that `blockByBlockParsing` and `controlFlow` do, plus individual line-level detail.
- `blockByBlockParsing` activates block-level structure plus `controlFlow` output.
- `controlFlow` is the lightest — only if/else-if/else branch decisions.
- `printParsedTree` is independent of the above — it fires after parsing completes (both in `TemplateEvaluator` and `ScriptFileExecutor`) and dumps the full AST before execution begins. Use it when parsing succeeds but execution behaves unexpectedly.
- `fileGeneration` is independent — it traces the file I/O layer regardless of parsing/execution verbosity.

### Typical Combinations

**"Which files are being generated?"**
```swift
config.flags.fileGeneration = true
```

**"Why is this template producing wrong output?"**
```swift
config.flags.lineByLineParsing = true
// or, less noisy:
config.flags.blockByBlockParsing = true
config.flags.controlFlow = true
```

**"Where are files landing on disk?"**
```swift
config.flags.fileGeneration = true
config.flags.changesInWorkingDirectory = true
```

**"Is my template even being reached?"**
```swift
config.flags.excludedFiles = true
config.flags.renderingStoppedInFiles = true
config.flags.fileGeneration = true
```

---

## 4. Event Hooks (`CodeGenerationEvents`)

Event hooks let you run custom closures at specific moments in the pipeline. They are set on `config.events` and offer two key capabilities:

1. **Conditional debug activation** — turn on `lineByLineParsing` only for a specific file or object, keeping the rest of the run quiet.
2. **Selective file skipping** — return `false` from `onBeforeRenderFile` or `onBeforeRenderTemplateFile` to prevent a file from being generated.

### Available Hooks

#### `onBeforeRenderTemplateFile`

**Signature:** `(fileName: String, templateName: String, pInfo: ParsedInfo) throws -> Bool`

Called before every template-based file render. Receives both the output filename and the template name. Return `false` to skip rendering that file.

```swift
config.events.onBeforeRenderTemplateFile = { filename, templateName, pInfo in
    // Turn on line-by-line tracing only for a specific output file
    if filename.is("user.service.ts") {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
    return true  // return false to skip this file entirely
}
```

This is the most powerful targeted debugging hook. It lets you get full verbose output for one file without drowning in logs from every other file.

#### `onBeforeRenderFile`

**Signature:** `(fileName: String, pInfo: ParsedInfo) throws -> Bool`

Called before rendering any output file (not just template-rendered ones). Return `false` to skip.

```swift
config.events.onBeforeRenderFile = { filename, context in
    if filename.lowercased() == "organization".lowercased() {
        print("rendering \(filename)")
    }
    return true
}
```

#### `onBeforeParseTemplate`

**Signature:** `(templateName: String, ctx: GenerationContext) throws -> Void`

Called before a `.teso` template file is parsed. Use to set breakpoints or log when a specific template enters parsing.

```swift
config.events.onBeforeParseTemplate = { templatename, context in
    if templatename.lowercased() == "entity.validator.teso".lowercased() {
        print("about to parse: \(templatename)")
    }
}
```

#### `onBeforeExecuteTemplate`

**Signature:** `(templateName: String, ctx: GenerationContext) throws -> Void`

Called after parsing but before executing a template. If parsing succeeded but output is wrong, hook here to confirm the template reached execution.

```swift
config.events.onBeforeExecuteTemplate = { templatename, context in
    if templatename.lowercased() == "entity.validator.teso".lowercased() {
        print("about to execute: \(templatename)")
    }
}
```

#### `onBeforeParseScriptFile`

**Signature:** `(templateName: String, ctx: GenerationContext) throws -> Void`

Called before a `.ss` script file is parsed. Useful for tracing when `main.ss` or any other script enters the parser.

```swift
config.events.onBeforeParseScriptFile = { scriptname, context in
    print("parsing script: \(scriptname)")
}
```

#### `onBeforeExecuteScriptFile`

**Signature:** `(templateName: String, ctx: GenerationContext) throws -> Void`

Called after parsing but before executing a `.ss` script file. Use this to confirm a script was parsed successfully and is about to run.

```swift
config.events.onBeforeExecuteScriptFile = { scriptname, context in
    print("executing script: \(scriptname)")
}
```

#### `onStartParseObject`

**Signature:** `(objectName: String, pInfo: ParsedInfo) throws -> Void`

Called when the DSL model parser begins parsing a domain object, DTO, or UIView. Use this to enable verbose logging only while a specific model object is being parsed.

```swift
config.events.onStartParseObject = { objname, pInfo in
    print(objname)  // log every object name as it's parsed
    if objname.lowercased() == "airport".lowercased() {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
}
```

### Combining Hooks and Flags

The recommended pattern for targeted debugging is:

1. Leave all global flags `false`.
2. Use an event hook to enable `lineByLineParsing` (or other flags) only when a specific file/object is being processed.
3. Disable the flag in the `else` branch so the rest of the run stays clean.

---

## 5. Error Output Options

When the pipeline throws an error, `PipelineErrorPrinter` formats the output. You can control what's included:

```swift
config.errorOutput.includeMemoryVariablesDump = true
```

### What Appears in Error Output

Every error report includes:

1. **Error category and location** — file identifier, line number, and error message. Categories:
   - `ERROR WHILE PARSING` — DSL template parsing errors (`ParsingError`)
   - `ERROR WHILE PARSING MODELS` — model file parsing errors (`Model_ParsingError`)
   - `ERROR DURING EVAL` — expression evaluation errors (`EvaluationError`)
   - `UNKNOWN ERROR` — other errors with `ParsedInfo`
   - `UNKNOWN INTERNAL ERROR` — unexpected errors without location info

2. **Extra Debug Info** — any entries accumulated in the context's `DebugDictionary`. These are set programmatically via `context.debugInfo.set(key, value:)` and `context.debugInfo.title(_:)`.

3. **Call Stack** — a trace of nested render/script calls showing `file [lineNo] >> line_content` for each stack frame. This is the most useful part — it tells you the chain of template/script files that led to the error.

4. **Memory Variables Dump** (opt-in) — when `config.errorOutput.includeMemoryVariablesDump = true`, dumps all current context variables and their values. Helpful when an expression fails because a variable has an unexpected value or is `nil`.

### Pipeline Phase Identification

Errors are also wrapped with the pipeline phase that failed:

```
❌❌ ERROR OCCURRED IN Render Phase ❌❌
```

This appears before the detailed error, so you immediately know which phase crashed.

---

## 6. In-Template Debugging (SoupyScript)

When the issue is inside a `.teso` template or `.ss` script, use these SoupyScript statements to probe values at runtime.

### `console-log <expression>`

Prints a value to stdout with a line-number tag. Works on strings, objects, and expressions. The most useful in-template debug tool.

In `.ss` scripts:
```
console-log @container.name
console-log "current module: " + module.name
```

In `.teso` templates (`:` prefix):
```
:console-log @container.name
:console-log prop.type
```

**Output format:** `🏷️ [Line N] <value>`

If the expression resolves to nothing: `🏷️🎈[Line no: N] - nothing to show`

### `announce <expression>`

A lighter-weight log that prints without a line number. Useful for progress markers.

In `.ss` scripts:
```
announce "Processing module: " + module.name
```

**Output format:** `🔈 <value>`

### `fatal-error <expression>`

Halts the pipeline immediately with an error message. Use this as an assertion — if the pipeline reaches a state that should be impossible, `fatal-error` stops execution and reports the location.

```
:if prop.type == "unknown"
:fatal-error "Unexpected type for property: " + prop.name
:end-if
```

### `stop-render`

Stops rendering the current template file without an error. The file is silently dropped. Useful for conditionally excluding an entire file when front-matter `include-if` isn't sufficient.

```
:if @container.name == "Internal"
:stop-render
:end-if
```

When `config.flags.renderingStoppedInFiles = true`, you'll see: `⚠️ Stop Rendering <filepath> ...`

### SoupyScript Comments

Lines starting with `//` inside `.teso` and `.ss` files are treated as comments and skipped during parsing. When `config.flags.onCommentedLines = true`, these are printed as `[lineNo] <line>`. You can use this to confirm that a specific section of a template is being reached during parsing, even if it doesn't produce output.

---

## 7. Front-Matter Directives & File Exclusion

`.teso` template files can have a front-matter block (between `---` fences) that controls whether the file is included in output. This is relevant to debugging because a missing file in output may be due to front-matter exclusion rather than a bug.

### `include-if`

Evaluates a boolean expression. If `false`, the entire file is excluded (no output generated).

```
---
/include-if: @container.containerType == "microservices"
---
... template body ...
```

When the file is excluded, it throws a `ParserDirective.excludeFile` internally. If `config.flags.excludedFiles = true`, you'll see: `⚠️ Excluding <filepath> ...`

### `include-for`

Marks the file for inclusion only for certain iteration contexts. Handled by the rendering layer.

### `file-name`

Overrides the output filename dynamically.

### Front-Matter Variables

Any non-directive key-value pair in front matter sets a variable in the context for that template's scope:

```
---
prefix: Api
suffix: Controller
---
{{ prefix }}{{ entity.name }}{{ suffix }}
```

If your output has unexpected values, check whether front-matter variables are shadowing context variables set elsewhere.

---

## 8. Error Reporting & Call Stack

### Error Types

ModelHike has a structured error hierarchy. Each error type carries a `ParsedInfo` with the file identifier and line number:

| Error Type | When It Fires |
|---|---|
| `Model_ParsingError` | Invalid syntax in `.modelhike` model files (bad property, method, container, module, annotation, API lines) |
| `ParsingError` | Invalid syntax during template/script parsing |
| `TemplateSoup_ParsingError` | Template-specific parse failures: missing modifiers, invalid expressions, unknown variables, bad function calls, wrong types |
| `EvaluationError` | Runtime failures: invalid state, missing models, write failures, missing blueprints/templates/scripts |
| `TemplateSoup_EvaluationError` | Template runtime failures: unidentified statements, working directory not set, template/script not found, non-sendable values |

### Call Stack

The `CallStack` is automatically maintained during template/script execution. Every `render-file`, `render-folder`, script execution, and special activity pushes a frame. When an error occurs, the call stack is unwound and printed, giving you a trace like:

```
[Call Stack]
 main.ss [42] >> render-file entity.service.teso as user.service.ts
 entity.service.teso [15] >> {{ prop.type | typename }}
```

This tells you that `main.ss` line 42 called `render-file`, and within that template at line 15, the expression failed.

### `DebugDictionary`

The context's `debugInfo` enriches error reports with extra context. When an error occurs, its key-value pairs appear under `[Extra Debug Info]`.

Currently, the **only place** that populates `debugInfo` is `TemplateFunction.swift` — when a user-defined template function (macro) executes, it records:
- `debugInfo.title("<functionName> Function Params:-")` — sets the section header and clears prior entries
- `debugInfo.set(argName, value: evaluatedValue)` — stores each argument's name and resolved value

This means that if an error occurs **inside a template function body**, the error output will include the function name and all argument values that were passed. Outside of template functions, `[Extra Debug Info]` will be empty.

> **Note:** `TemplateSoupExpressionDebugInfo` is defined in `ContextState + Symbol.swift` but is currently unused — it appears to be scaffolding for future expression-level debug data.

---

## 9. Isolating a Single File or Object

### By Output Filename

Use `onBeforeRenderTemplateFile` to activate tracing for one file:

```swift
config.events.onBeforeRenderTemplateFile = { filename, templateName, pInfo in
    if filename.is("user.service.ts") {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
    return true
}
```

### By Template Name

Target the template itself rather than the output file:

```swift
config.events.onBeforeRenderTemplateFile = { filename, templateName, pInfo in
    if templateName.lowercased() == "entity.service.teso".lowercased() {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
    return true
}
```

### By Model Object Name

Target parsing of a specific domain object in the `.modelhike` file:

```swift
config.events.onStartParseObject = { objname, pInfo in
    if objname.lowercased() == "user".lowercased() {
        pInfo.ctx.debugLog.flags.lineByLineParsing = true
    } else {
        pInfo.ctx.debugLog.flags.lineByLineParsing = false
    }
}
```

### Skip a File Entirely

Return `false` from a render hook to prevent generation, useful for narrowing down which file introduces a problem:

```swift
config.events.onBeforeRenderFile = { filename, pInfo in
    return filename.lowercased() != "problematic-file".lowercased()
}
```

---

## 10. Isolating with `runTemplateStr()`

For expression-level debugging, bypass the full pipeline entirely. `DevMain.swift` has a `runTemplateStr()` function that renders a single template string against hardcoded data:

```swift
static func runTemplateStr() async throws {
    let templateStr = "{{ (var1 and var2) and var2}}"
    let data: [String : Sendable] = ["var1" : true, "var2": false, "varstr": "test"]

    let ws = Pipelines.empty
    if let result = try await ws.render(string: templateStr, data: data) {
        print(result)
    }
}
```

Switch to it by commenting out `runCodebaseGeneration()` and uncommenting `runTemplateStr()` in `main()`:

```swift
static func main() async {
    do {
        try await runTemplateStr()
        //try await runCodebaseGeneration()
    } catch {
        print(error)
    }
}
```

This is the fastest way to test:
- Expression syntax (`{{ }}` blocks)
- Modifier behaviour (`{{ value | modifier }}`)
- Operator evaluation (`and`, `or`, comparisons)
- Conditional logic (`:if` / `:else` / `:end-if`)
- Inline function calls

---

## 11. Isolating with Inline Models

When a model parsing issue is hard to isolate in a large `.modelhike` file, you can define a minimal model directly in Swift code using `InlineModelLoader`. This bypasses file discovery entirely and lets you test parsing with a controlled, minimal input.

`DevMain.swift` already has a helper for this:

```swift
private static func inlineModel(_ ws: Workspace) async -> InlineModelLoader {
    return await InlineModelLoader(with: ws.context) {
        InlineModel {
            """
            ===
            APIs
            ====
            + Registry Management

            === Registry Management ===

            Registry
            ========
            * _id: Id
            * name: String
            - desc: String
            """
        }
        getCommonTypes()
    }
}
```

To use it, you would switch the pipeline's model loading to use the inline loader instead of `LocalFileModelLoader`. This is useful when you want to:

- Test whether a specific DSL construct parses correctly
- Reproduce a parsing error with a minimal model
- Verify hydration/annotation behaviour on a small model without external files

---

## 12. Scoping the Run with `containersToOutput`

Limit code generation to specific containers to reduce noise and speed up iteration:

```swift
config.containersToOutput = ["APIs"]
```

The pipeline will only generate output for the named container(s), skipping all others. This is set in `DevMain.swift` and is the first thing to narrow when debugging.

---

## 13. Using the Xcode Debugger

When the higher-level tools aren't enough, you can use Xcode's native debugger against the `DevTester` target.

### Breakpoints

Set breakpoints in the Swift source to inspect state at any point during the pipeline:

- **Model parsing** — breakpoint in `DomainObjectParser`, `DtoObjectParser`, `UIViewParser`, or `ModelFileParser` to inspect how DSL lines are interpreted.
- **Template rendering** — breakpoint in `TemplateEvaluator.execute(lineParser:with:)` or `ScriptFileExecutor.execute(lineParser:with:)` to step through template/script execution.
- **Expression evaluation** — breakpoint in `ExpressionEvaluator.evaluate(expression:pInfo:)` to see how expressions resolve.
- **Error handling** — breakpoint in `PipelineErrorPrinter.printError(_:context:)` to inspect the full error and context before it's formatted for output.
- **File generation** — breakpoint in `CodeGenerationSandbox.generateFile(_:template:with:)` to inspect what's being generated and where.

### Swift Call Stack

The `PipelineErrorPrinter` has commented-out `Thread.callStackSymbols` calls. If the ModelHike-level call stack (which tracks template/script nesting) isn't sufficient, you can uncomment these to get the full Swift call stack:

```swift
// In PipelineErrorPrinter.printError(_:context:)
print(Thread.callStackSymbols)  // uncomment for Swift-level stack trace
```

### Conditional Breakpoints

Since the pipeline processes many objects and files, Xcode conditional breakpoints are valuable. For example, break only when rendering a specific file:

- In `CodeGenerationSandbox.generateFile`, condition: `filename == "user.service.ts"`
- In `DomainObjectParser`, condition: `name == "Airport"`

---

## 14. Common Debugging Scenarios

### "A file is missing from the output"

1. Enable `config.flags.fileGeneration = true` — look for `⚠️ File ... not Generated!!!` messages.
2. Enable `config.flags.excludedFiles = true` — check if the file was excluded by front-matter directives.
3. Enable `config.flags.renderingStoppedInFiles = true` — check if `stop-render` halted it.
4. Hook `onBeforeRenderTemplateFile` and print all filenames to see if the file was ever attempted.

### "A file has wrong content"

1. Use `onBeforeRenderTemplateFile` to enable `lineByLineParsing` for that specific file.
2. Add `console-log` statements in the `.teso` template to inspect variable values at key points.
3. Check `controlFlow` flag to see which `if`/`else` branches are taken.
4. Enable `config.errorOutput.includeMemoryVariablesDump = true` if you suspect a variable has an unexpected value.

### "An expression fails or returns unexpected values"

1. Use `runTemplateStr()` to test the expression in isolation with known data.
2. In the template, add `:console-log <variable>` before the failing expression to verify inputs.
3. Enable `config.errorOutput.includeMemoryVariablesDump = true` to see all variables at the point of failure.

### "Model parsing is wrong"

1. Hook `onStartParseObject` to log every object as it's parsed.
2. Enable `lineByLineParsing` for the specific object that's wrong.
3. Check the error output — `Model_ParsingError` gives the exact line and error type.

### "Files are landing in the wrong directory"

1. Enable `config.flags.changesInWorkingDirectory = true` to trace `working_dir` changes.
2. Enable `config.flags.fileGeneration = true` to see the full output path for each file.
3. Add `console-log working_dir` in your `.ss` script at key points.

### "The pipeline crashes with no useful error"

1. Enable `config.errorOutput.includeMemoryVariablesDump = true` for a full variable dump.
2. The error output always includes a call stack — read it bottom-to-top to find the originating file and line.
3. If the error is `UNKNOWN INTERNAL ERROR`, it's a Swift-level error outside the structured error hierarchy. The raw `error` is printed; use Xcode's debugger with a breakpoint on the throw.

### "I want to trace the full flow of `main.ss`"

1. Set `config.flags.blockByBlockParsing = true` for a high-level trace of script execution blocks.
2. Or set `config.flags.lineByLineParsing = true` for full verbosity (very noisy for large blueprints).
3. Add `announce` statements in `main.ss` at section boundaries for human-readable progress markers.
4. Hook `onBeforeParseScriptFile` and `onBeforeExecuteScriptFile` to confirm the script is being found and reached.

### "A template is producing wrong output but I'm not sure which if-branch is taken"

1. Enable `config.flags.controlFlow = true` — this logs every `IF Condition Satisfied`, `ELSE IF Condition Satisfied`, and `ELSE Block executing` with the line number and condition.
2. If you need it for just one file, use `onBeforeRenderTemplateFile` to set `controlFlow = true` only for that file.
3. Add `:console-log` before each branch to print variable values that feed into the condition.

### "An expression evaluates to something unexpected"

1. Use `:console-log <variable>` to print the raw value before it enters the expression.
2. Use `runTemplateStr()` to test the expression in isolation with known data (see [section 10](#10-isolating-with-runtemplatestr)).
3. Enable `config.flags.printParsedTree = true` to see how the parser interpreted the expression (it shows the full AST including the expression node).
4. If the expression involves modifiers, verify the modifier is loaded — a `modifierNotFound` error means the modifier wasn't registered. Check that the correct `loadSymbols()` call was made (`.typescript`, `.java`, etc.) and that any blueprint-defined modifiers are in the `_modifiers_/` folder.

### "A `working_dir` issue — files appear in the wrong place"

1. Enable `config.flags.changesInWorkingDirectory = true`.
2. Enable `config.flags.fileGeneration = true` to see where each file is being written.
3. In your `.ss` script, add `console-log working_dir` at key points to see the current value.
4. Remember that `set working_dir` in a script changes the output subdirectory — if it's set wrong, all subsequent `render-file` calls land in the wrong location.

### "Pipeline passes are being skipped"

If a pipeline phase has no passes, it prints `⦻ Phase <name> cannot run!!! ⦻ No passes to run!!!...`. If an individual pass fails its `canRunIn` check, it prints `⦻ Pass <name> cannot run!!!...`. These are always-on messages (no flag needed). Check the output for these markers.

### "Error inside a template function (macro) — what arguments were passed?"

If a `fatal-error` or expression error occurs inside a user-defined template function, the error output automatically includes `[Extra Debug Info]` showing the function name and all argument values. No flags needed — `TemplateFunction.swift` populates `debugInfo` on every function call.

### "A modifier produces wrong output"

The modifier chain (`Modifiers.apply()`, `ModifierInstance`, built-in and blueprint-defined modifiers) has **no internal debug hooks or logging**. To debug a modifier:

1. Add `:console-log <value>` before the modifier call to see the input value.
2. Add `:console-log` after the expression to see the output.
3. Test the modifier in isolation using `runTemplateStr()`.
4. If it's a blueprint-defined modifier (from `_modifiers_/`), read the `.teso` file — it's a regular template you can reason about.
5. If the error is `modifierNotFound`, verify the modifier is registered: check `loadSymbols()` in `GenerateCodePass.swift` and that any blueprint `_modifiers_/` folder exists and contains `.teso` files.

---

## 15. Blueprint-Specific Debugging Patterns

The blueprints in `modelhike-blueprints` have their own debugging conventions worth knowing.

### Current Blueprints

| Blueprint | Stack | Entry Point |
|---|---|---|
| `api-nestjs-monorepo` | NestJS + TypeScript + MongoDB | `main.ss` |
| `api-springboot-monorepo` | Spring Boot 3.x + Java + GraphQL + MongoDB | `main.ss` |

### `announce` as Progress Markers

Both blueprints use `announce` at the start of `main.ss` as a progress marker:

```
announce "Generating NestJs Apis (monorepo) ..."
announce "Generating SpringBoot Reactive Apis (monorepo) ..."
```

Neither blueprint uses `console-log` — it's purely a developer-added debug tool you'd insert temporarily when investigating issues.

### `fatal-error` as Runtime Assertions

Both blueprints use `fatal-error` to catch unknown API types:

```
fatal-error unknown api '{{api.name}}', with type '{{api.type}}'
```

This fires when an API type falls through all known `if`/`else-if` branches. If you see this error, it means the model defines an API type that the blueprint doesn't handle yet.

### `working_dir` Routing Patterns

Blueprints use `set` and `set-str` to route output files to different directories. Understanding these patterns is critical when files end up in the wrong place:

**NestJS example flow:**
```
set working_dir = "/libs/domain-models"       // shared domain models
set working_dir = "/libs/validation"           // validation schemas
set-str working_dir = /apps/{{module}}/src/{{submodule}}/crud   // CRUD files per entity
set-str working_dir = /apps/{{module}}/src/    // module-level files
set working_dir = "/docs/class-diag"           // documentation
set working_dir = "/"                          // root (for copy-folder "libs")
```

**SpringBoot example flow:**
```
set working_dir = "/"                          // root
set-str entity_dir = /base-services/{{module}}/src/{{pkg}}/{{submodule}}/  // entity files
set-str working_dir = /base-services/{{module}}/resources/graphql          // GraphQL schemas
set working_dir = "/docs/class-diag"           // documentation
```

### Front-Matter Usage in Blueprints

The SpringBoot blueprint uses front-matter extensively in `.teso` files for conditional generation:

```
---
/include-for : api in apis
/include-if : api.is-create
---
```

This means many template files are **conditionally generated** per API. If a file is missing from output, the `include-if` condition likely evaluated to `false`. Enable `config.flags.excludedFiles = true` to confirm.

Files using `/file-name` to dynamically rename output:
```
---
/include-for : api in apis
/include-if : api.is-custom-logic
/file-name : {{api.name}}.java
---
```

### No `_modifiers_/` in Current Blueprints

Neither blueprint has a `_modifiers_/` folder. All modifiers come from the engine's built-in libraries (`TypescriptLib`, `JavaLib`, `MongoDB_TypescriptLib`, `GraphQLLib`, etc.). The `_modifiers_/` system is available but not currently used by the shipped blueprints.

### Blueprint `main.ss` Front Matter

Both blueprints define configuration variables in their `main.ss` front matter:

**NestJS:**
```
-----
Product-name : GenProduct
Company-name : WowCompany
-----
```

**SpringBoot:**
```
-----
api-base-path : /api/v1
-----
```

These set context variables available throughout the blueprint's templates. If output contains unexpected product names or API paths, check these values.

---

## Appendix: Where the Debug Infrastructure Lives

| File | What It Contains |
|---|---|
| `Sources/Workspace/Context/DebugUtils.swift` | `ContextDebugLog` class and `ContextDebugFlags` struct — all flag-gated print methods |
| `Sources/Workspace/Context/CodeGenerationEvents.swift` | `CodeGenerationEvents` actor — all hook type aliases and dispatch methods |
| `Sources/Pipelines/PipelineConfig.swift` | `PipelineConfig` struct — where `flags`, `events`, and `errorOutput` live on the config |
| `Sources/Pipelines/PipelineErrorPrinter.swift` | `PipelineErrorPrinter` — formats error output with call stack and memory dump |
| `Sources/Workspace/Context/CallStack.swift` | `CallStack` actor — push/pop stack frames during rendering |
| `Sources/Workspace/Context/ContextState + Symbol.swift` | `DebugDictionary` actor — extra debug info attached to errors |
| `Sources/Scripting/SoupyScript/Stmts/ConsoleLog.swift` | `console-log` statement implementation |
| `Sources/Scripting/SoupyScript/Stmts/AnnnounceStmt.swift` | `announce` statement implementation |
| `Sources/Scripting/SoupyScript/Stmts/Stop.swift` | `stop-render` statement implementation |
| `Sources/Scripting/SoupyScript/Stmts/ThrowError.swift` | `fatal-error` statement implementation |
| `Sources/Scripting/_Base_/Parsing/FrontMatter.swift` | Front-matter parsing — `include-if`, `include-for`, `file-name` directives, variable injection |
| `Sources/Scripting/_Base_/Parsing/ParserDirective.swift` | `ParserDirective` enum — `excludeFile`, `stopRenderingCurrentFile`, `throwErrorFromCurrentFile` |
| `Sources/Scripting/_Base_/Parsing/ParsedInfo.swift` | `ParsedInfo` struct — carries file identifier, line number, parser ref, context for every error |
| `Sources/Scripting/_Base_/ScriptFileExecutor.swift` | Executes `.ss` script files — fires parse/execute hooks, prints AST via `printParsedTree` |
| `Sources/CodeGen/TemplateSoup/TemplateEvaluator.swift` | Executes `.teso` templates — fires parse/execute hooks, handles directives, prints AST |
| `Sources/Workspace/Evaluation/ExpressionEvaluator.swift` | Core expression evaluator — where `{{ }}` expressions resolve to values |
| `Sources/Pipelines/Pipeline.swift` | Phase-level error wrapping and `PipelineErrorPrinter` invocation |
| `Sources/Pipelines/PipelinePhase.swift` | Per-phase pass execution — logs when passes/phases cannot run |
| `Sources/Pipelines/1. Discover/DiscoverModels.swift` | Logs when no model files are found |
| `Sources/Pipelines/2. Load/LoadModels.swift` | Logs loaded type counts; catches and reports model loading errors |
| `Sources/Pipelines/6. Persist/GenerateOutputFolders.swift` | Logs final file/folder generation counts |
| `Sources/_Common_/Errors/ParsingError.swift` | `ParsingError` enum — generic template/script parse failures |
| `Sources/_Common_/Errors/EvaluationError.swift` | `EvaluationError` enum — runtime evaluation failures |
| `Sources/Scripting/_Base_/Parsing/TemplateSoup_ParsingError.swift` | Template-specific parse errors (missing modifiers, bad expressions, unknown variables) |
| `Sources/Workspace/Evaluation/TemplateSoup_EvaluationError.swift` | Template runtime errors (unidentified stmts, missing templates/scripts, non-sendable values) |
| `Sources/Modelling/_Base_/ModelErrors.swift` | `Model_ParsingError` enum — DSL model file parse errors |
| `DevTester/DevMain.swift` | Development harness with commented-out examples of all debugging patterns |
| `DevTester/Environment.swift` | Path configuration — verify `basePath` and `localBlueprintsPath` are correct |
