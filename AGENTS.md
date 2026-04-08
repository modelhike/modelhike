# AGENTS.md — ModelHike MCP & Smart CLI

> **Auto-update policy:** Any agent modifying this codebase MUST update this file when changes affect architecture, public APIs, command signatures, MCP tool schemas, diagnostic codes, file structure, dependencies, or conventions documented here. When in doubt, update. Stale docs are worse than no docs.

---

## Project Identity

**ModelHike Smart CLI** is a non-interactive command-line interface and MCP (Model Context Protocol) server for [ModelHike](https://github.com/modelhike/modelhike) — a deterministic code generation engine driven by `.modelhike` model files.

ModelHike is not a code generator that uses AI. It is a **deterministic compilation target for AI**. The `.modelhike` file is the intermediate representation between human intent and production code. Any AI can write to it. ModelHike guarantees the output.

This package provides the structured interface layer: the CLI and MCP server handle parsing inputs, invoking the ModelHike pipeline at the correct phase, and returning structured, machine-readable results. The AI handles the creative part (turning intent into a model). ModelHike handles the deterministic part (validating and generating from the model). Clean separation of concerns.

### What "Smart CLI" Means

A smart CLI is designed for use by **both humans and AI agents**:

- Zero interactivity — all inputs via arguments, flags, or stdin
- Structured output — human-readable by default, JSON available with `--format json`
- Diagnostic codes — every issue carries a code (W301, W302...), message, source location, and machine-actionable suggestions
- Meaningful exit codes — 0 success, 1 warnings, 2 errors, 3 parse failure, 4 generation failure
- stdin model input — `--input -` reads `.modelhike` content from stdin (primary AI agent flow)
- Deterministic — same input always produces the same output

---

## Architecture Overview

Four SPM targets in one package:

```
modelhike-smart-cli/
├── DevTester_MCP/        # In-repo MCP smoke-test target sources + docs
├── Sources/
│   ├── ModelHikeKit/     # Shared engine library
│   ├── CLI/              # `modelhike` executable (swift-argument-parser)
│   └── MCP/              # `modelhike-mcp` executable (MCP SDK, stdio transport)
├── Tests/
│   └── ModelHikeKitTests/
├── docs/
├── Package.swift
└── AGENTS.md             # THIS FILE
```

**Dependency graph:**

```
modelhike (CLI executable)
  ├── ModelHikeKit (library)
  │     ├── ModelHike (github: modelhike/modelhike, branch main)
  │     └── ModelHike.Blueprints (github: modelhike/modelhike-blueprints, branch main)
  ├── ModelHike.Blueprints
  └── swift-argument-parser 1.7.1

modelhike-mcp (MCP server executable)
  ├── ModelHikeKit (library)
  ├── ModelHike.Blueprints
  └── modelcontextprotocol/swift-sdk 0.12.0

DevTester_MCP (dev smoke-test executable)
  ├── MCP Client (swift-sdk 0.12.0)
  ├── swift-argument-parser 1.7.1
  ├── swift-log 1.11.0
  └── custom child-process stdio transport for launching `modelhike-mcp`
```

**ModelHikeKit** is the shared brain. Both CLI and MCP call into it. Never put command-specific logic in ModelHikeKit — it exposes pure async functions that return Codable result types.

---

## The ModelHike Core Library

The upstream `ModelHike` package is a remote dependency (`github: modelhike/modelhike`, `main` branch). This section documents the parts of that library that `ModelHikeKit` uses directly.

> **Important:** The Smart CLI uses the core library's `Pipeline` abstraction for the actual load/hydrate/validate/render work. `ModelHikeEngine` still resolves CLI/MCP inputs itself so it can support stdin, single-file input, and adjacent support files consistently, then feeds that resolved content into upstream partial pipelines via `InlineModelLoader` while preserving per-input source identifiers for diagnostics.

### Conceptual Phases

The core library defines a phased pipeline:

```
Discover → Load → Hydrate → Validate → Render → Persist
```

The Smart CLI engine maps each command onto an upstream partial pipeline:

| Command            | Equivalent Phases                        | Stops Before |
|--------------------|------------------------------------------|-------------|
| `validate`         | Load, Hydrate, Validate                  | Render      |
| `generate`         | Load, Hydrate, Validate, Render, Persist | —           |
| `dry-run`          | Load, Hydrate, Validate, Render          | Persist     |
| `explain`          | Load, Hydrate                            | Validate    |
| `inspect`          | Load, Hydrate                            | Validate    |
| `what-depends-on`  | Load, Hydrate                            | Validate    |
| `list-types`       | Load, Hydrate                            | Validate    |
| `fix`              | Load, Hydrate, Validate                  | Render      |
| `preflight`        | Load, Hydrate, Validate + blueprint checks | Render    |
| `list-blueprints`  | Bundled official blueprints + overrides  | —           |
| `dsl-schema-in-markdown` | — (reads bundled DSL docs from core lib) | —       |

### How the Engine Loads Models

For all input modes, the engine:

1. Resolves `ModelInput` into domain model text plus optional `common.modelhike` and `main.tconfig` support files
2. Creates a `PipelineConfig` + `DefaultDebugRecorder`
3. Builds an upstream partial `Pipeline` for the requested command
4. Attaches an `InlineModelLoader` using `pipeline.ws.context`
5. Runs the upstream load/hydrate/validate/render passes and maps the resulting debug session into Smart CLI result types

For stdin/MCP content, the string is treated as one inline domain model with identifier `stdin.modelhike`. For file/directory inputs, the engine still resolves and reads adjacent support files from the filesystem before passing them into `InlineModelLoader`, preserving filenames like `common.modelhike`, `main.tconfig`, and the original model filenames so parse/runtime diagnostics keep their source identity.

### .modelhike DSL Syntax

The DSL is line-oriented, parsed by `ModelFileParser`. Key patterns:

```
===                           # Container start fence
Container Name                # Container name
====                          # Container end fence
+ Module Name                 # Module inclusion

=== Module Name ===           # Module/component definition

EntityName                    # Entity block start
==========                    # Entity underline (length doesn't matter)
* requiredField: Type         # Required property (* = mandatory, ** = primary key)
- optionalField: Type         # Optional property
~ methodName(param): Return   # Method
* refs: Type[1..*]            # Cardinality
* linked: Reference@Target    # Reference to another entity
- audit: Audit (backend)      # Annotation in parentheses
#blueprint(spring-boot)       # Tag on container — selects which blueprint to use
```

### Diagnostic Codes

`W301`-`W306` are emitted by upstream `ValidateModelsPass`. Those validation warnings now preserve parsed file/line locations when the upstream model nodes carry source metadata. `W307` and `E101` come from upstream generation / blueprint loading:

| Code | Severity | Meaning |
|------|----------|---------|
| W301 | warning  | Unresolved custom type reference on a property |
| W302 | warning  | Unresolved `@Name` expression/constraint reference |
| W303 | warning  | Unresolved `+ module` reference on a container |
| W304 | warning  | Duplicate normalized type name |
| W305 | warning  | Duplicate property name within a type |
| W306 | warning  | Duplicate method name within a type |
| W307 | warning  | Container missing `#blueprint(name)` tag (emitted by GenerateCodePass) |
| E101 | error    | Blueprint missing required `main.ss` entry point script |

Diagnostics are captured via `DefaultDebugRecorder` attached to `PipelineConfig.debugRecorder`. After a pipeline run, extract diagnostics from `DebugEventEnvelope` events with `.diagnostic(...)` case.

Each diagnostic includes:
- `DiagnosticSeverity`: error, warning, info, hint
- Optional `code`: string like "W301"
- `message`: human-readable description
- `SourceLocation`: fileIdentifier, lineNo, lineContent, level
- `[DiagnosticSuggestion]`: each with kind (didYouMean, availableOptions, note), message, optional replacement, options list

### Blueprint System

Blueprints are folders containing `main.ss` (SoupyScript) and `.teso` templates. Each subfolder name = one blueprint name.

The engine uses two blueprint sources:

1. **`OfficialBlueprintFinder`** (from `modelhike-blueprints` package) — provides bundled official blueprints (e.g. `api-nestjs-monorepo`, `api-springboot-monorepo`). Always registered automatically.
2. **`config.localBlueprintsPath`** — optional local filesystem blueprints layered on top. Set via `--blueprints` flag or `MODELHIKE_BLUEPRINTS` env var.

Key types:
- `OfficialBlueprintFinder` — from `ModelHike.Blueprints` package, discovers bundled blueprints
- `BlueprintAggregator` — orchestrates discovery across all `BlueprintFinder`s
- `LocalFileBlueprintFinder` — lists subfolder names under a root path
- `LocalFileBlueprint` — loads scripts/templates from a blueprint folder
- `BlueprintFinder` protocol — `blueprintsAvailable: [String]`, `hasBlueprint(named:)`, `blueprint(named:with:)`

### Key Core Types

Types marked **used** are called directly by `ModelHikeEngine`. Types marked *unused* exist in the upstream library but are not used by the smart CLI.

| Type | Location | Used | Role |
|------|----------|------|------|
| `PipelineConfig` | `Sources/Pipelines/PipelineConfig.swift` | **yes** | All config: paths, flags, blueprints |
| `DefaultDebugRecorder` | `Sources/Debug/DebugRecorder.swift` | **yes** | Captures all events/diagnostics |
| `ModelSnapshot` | `Sources/Debug/ModelSnapshot.swift` | **yes** | Codable model snapshot for introspection |
| `Pipeline` | `Sources/Pipelines/Pipeline.swift` | **yes** | Phased pipeline runner used for partial pipelines |
| `Workspace` | `Sources/Workspace/Workspace.swift` | **yes** | Exposes `context` for `InlineModelLoader` bootstrapping |
| `InlineModelLoader` | `Sources/Modelling/_Base_/Loader/InlineModelLoader.swift` | **yes** | In-memory model source used for resolved CLI/MCP inputs |
| `HydrateModelsPass` | `Sources/Pipelines/3. Hydrate/HydrateModels.swift` | **yes** | Upstream hydration pass for partial pipelines |
| `PassDownAndProcessAnnotationsPass` | `Sources/Pipelines/3. Hydrate/PassDownAndProcessAnnotations.swift` | **yes** | Upstream annotation-processing pass |
| `ValidateModelsPass` | `Sources/Pipelines/3.5. Validate/ValidateModels.swift` | **yes** | Upstream semantic validation pass |
| `GenerateCodePass` | `Sources/Pipelines/5. Render/GenerateCodePass.swift` | **yes** | Upstream render pass used by `generate` |

All paths above are relative to the upstream `modelhike` package (resolved by SPM under `.build/checkouts/modelhike/`).

---

## ModelHikeKit API

### ModelHikeEngine

The single entry point. Stateless, `Sendable`. Create one per invocation.

```swift
public struct ModelHikeEngine: Sendable {
    public init(blueprintsPath: String? = nil)

    public func validate(_ input: ModelInput) async throws -> ValidationResult
    public func dryRun(
        _ input: ModelInput,
        blueprint: String? = nil,
        containers: [String] = [],
        systemViews: [String] = []
    ) async throws -> GenerationResult
    public func generate(
        _ input: ModelInput,
        blueprint: String? = nil,
        containers: [String] = [],
        systemViews: [String] = [],
        outputPath: String? = nil
    ) async throws -> GenerationResult
    public func generateInline(
        _ input: ModelInput,
        inlineBlueprint: InlineBlueprintSnapshot,
        containers: [String] = [],
        persist: Bool = false,
        outputPath: String? = nil
    ) async throws -> GenerationResult
    public func explain(_ input: ModelInput) async throws -> ExplanationResult
    public func inspect(_ input: ModelInput, entity: String) async throws -> InspectionResult
    public func whatDependsOn(_ input: ModelInput, entity: String) async throws -> DependencyResult
    public func listBlueprints() async throws -> BlueprintListResult
    /// Bundled canonical DSL markdown from upstream `ModelHikeDSLSchema.bundled` (`nil` only if resources are missing).
    public func dslSchemaMarkdown() -> ModelHikeDSLSchema?
}
```

### ModelInput

```swift
public enum ModelInput: Sendable {
    case content(String)      // Inline .modelhike DSL string (stdin / MCP)
    case file(String)         // Path to a single .modelhike file
    case directory(String)    // Path to directory containing .modelhike files
}
```

### Result Types

All result types are `Codable & Sendable`, located in `Sources/ModelHikeKit/Results/`.

**ValidationResult:**
```swift
public struct ValidationResult: Codable, Sendable {
    public let valid: Bool
    public let diagnostics: [Diagnostic]
    public let summary: DiagnosticSummary
}
```

**Diagnostic:**
```swift
public struct Diagnostic: Codable, Sendable {
    public let severity: DiagnosticSeverity  // .error, .warning, .info, .hint (String-backed enum)
    public let code: String?                 // "W301", "W302", etc.
    public let message: String
    public let source: SourceRef?
    public let suggestions: [Suggestion]
}
```

**GenerationResult:**
```swift
public struct GenerationResult: Codable, Sendable {
    public let files: [GeneratedFile]
    public let tree: String              // ASCII tree representation
    public let diagnostics: [Diagnostic]
    public let summary: GenerationSummary // { fileCount: Int }
}
```

**GeneratedFile:**
```swift
public struct GeneratedFile: Codable, Sendable {
    public let path: String
    public let content: String
    public let templateName: String?     // Blueprint template that produced this file
    public let objectName: String?       // Model object this file was generated for
}
```

**ExplanationResult:**
```swift
public struct ExplanationResult: Codable, Sendable {
    public let containers: [ContainerSummary]
    public let diagnostics: [Diagnostic]
    public let summary: ModelSummary     // { containerCount, moduleCount, entityCount, propertyCount, methodCount, apiCount }
}
```

**InspectionResult:**
```swift
public struct InspectionResult: Codable, Sendable {
    public let entity: EntityDetail?     // nil if the entity was not found
    public let references: [Reference]
    public let generatedArtifacts: [String]
    public let diagnostics: [Diagnostic]
}
```

**DependencyResult:**
```swift
public struct DependencyResult: Codable, Sendable {
    public let entity: String
    public let dependents: [Dependent]   // each: { entityName, location, referenceKind, rawValue }
    public let breakingChanges: [BreakingChange]
    public let diagnostics: [Diagnostic]
}
```

**TypeListResult:**
```swift
public struct TypeListResult: Codable, Sendable {
    public let types: [TypeInfo]         // each: { name, kind, module, container }
    public let diagnostics: [Diagnostic]
}
```

**FixResult:**
```swift
public struct FixResult: Codable, Sendable {
    public let fixed: Bool
    public let model: String?
    public let applied: [FixAction]
    public let remaining: [Diagnostic]
    public let diagnostics: [Diagnostic]
}
```

**PreflightResult:**
```swift
public struct PreflightResult: Codable, Sendable {
    public let ready: Bool
    public let checks: [PreflightCheck]
    public let recommendation: String
    public let diagnostics: [Diagnostic]
}
```

**BlueprintListResult:**
```swift
public struct BlueprintListResult: Codable, Sendable {
    public let blueprints: [BlueprintInfo]
    public let diagnostics: [Diagnostic]
}
```

**DSLMarkdownSchemaResult** (MCP / `--format json` for `dsl-schema-in-markdown`):
```swift
public struct DSLMarkdownSchemaResult: Codable, Sendable {
    public let modelHikeDSL: String      // content of modelHike.dsl.md
    public let codeLogicDSL: String      // content of codelogic.dsl.md
    public let templateSoupDSL: String   // content of templatesoup.dsl.md
}
```

The upstream `ModelHikeDSLSchema` type (three strings, loaded from the `ModelHikeDSL` resource bundle in the core package) is re-exported from ModelHikeKit as `ModelHikeDSLSchema`.

---

## CLI Commands

Executable: `modelhike` (target `ModelHikeCLI`, path `Sources/CLI/`)

### validate

```
modelhike validate [--input <path-or-stdin>] [--format json|human] [--blueprints <path>]
```

Parses model, runs hydration and validation. Returns structured diagnostics. Exit code reflects severity.

### generate

```
modelhike generate [--input <path-or-stdin>] [--blueprint <name>] [--container <name> ...] [--system-view <name> ...] [--output <dir>] [--format json|human] [--blueprints <path>]
```

Full pipeline through Persist. If `--blueprint` is omitted, generation uses the model's own `#blueprint(name)` tags. If `--blueprint` is provided, at least one target selector must also be provided. With `--output`, generated files are written there; otherwise they are persisted to `<basePath>/modelhike-output`.

### dry-run

```
modelhike dry-run [--input <path-or-stdin>] [--blueprint <name>] [--container <name> ...] [--system-view <name> ...] [--format json|human] [--blueprints <path>]
```

Runs the same load/hydrate/validate/render pipeline as `generate`, but stops before Persist. Returns the generated file manifest and tree preview without writing anything to disk.

### inline-generate

```
modelhike inline-generate --input <model-file-or-inline-string> --inline-blueprint <blueprint-json-file-or-inline-json-string> [--container <name> ...] [--output <dir>] [--format json|human]
```

Runs `InlineGenerationHarness` against a single inline model and an inline blueprint JSON payload. `--input` accepts either a file path or raw `.modelhike` text. `--inline-blueprint` accepts either a file path or a raw JSON string that decodes to `InlineBlueprintSnapshot`. No stdin mode for this command. Without `--output`, the command previews generated files without persisting them; with `--output`, it writes them there.

### explain

```
modelhike explain [--input <path-or-stdin>] [--format json|human]
```

Parses and hydrates model. Returns structured summary of containers, modules, entities, properties, methods, relationships. Designed for AI to present "here's what I'm about to generate" to the developer.

### inspect

```
modelhike inspect <entity> [--input <path-or-stdin>] [--format json|human]
```

Shows detail for a single entity: properties, methods, annotations, tags, cross-references, generated artifacts.

### what-depends-on

```
modelhike what-depends-on <entity> [--input <path-or-stdin>] [--change rename|remove] [--new-name <name>] [--format json|human]
```

Reverse dependency walk. Shows dependents across property types, method return types, annotations, tags, and `@Target` references. With `--change`, it also returns `breakingChanges` fix hints for rename/remove planning.

### list-types

```
modelhike list-types [--input <path-or-stdin>] [--format json|human]
```

Lists all declared model types, grouped by container and module.

### fix

```
modelhike fix [--input <path-or-stdin>] [--codes <W301,W307,...>] [--format json|human]
```

Attempts auto-repair for supported diagnostics and returns corrected model content plus an audit trail of applied and remaining fixes.

### preflight

```
modelhike preflight [--input <path-or-stdin>] [--blueprint <name>] [--format json|human]
```

Runs a generation-readiness checklist by combining validation diagnostics with blueprint availability checks.

### list-blueprints

```
modelhike list-blueprints [--blueprints <path>] [--format json|human]
```

Enumerates bundled official blueprints from the `modelhike-blueprints` package. If `--blueprints` is passed, those filesystem blueprints are added too, with local overrides taking precedence on lookup.

### dsl-schema-in-markdown

```
modelhike dsl-schema-in-markdown [--format json|human]
```

Prints the three canonical DSL specification files bundled inside the `modelhike` core package (`modelHike.dsl.md`, `codelogic.dsl.md`, `templatesoup.dsl.md`). Human format concatenates them with section headings; JSON format returns a `DSLMarkdownSchemaResult` object with three string fields. No `--input` or `--blueprints`. Exit code `4` if the resource bundle cannot be loaded.

### Common Flags

- `--input <path>` — file path, directory path, or `-` for stdin. Default: current directory. Present on all commands except `list-blueprints`, `dsl-schema-in-markdown`, and `inline-generate`.
- `--format json|human` — output format. Default: `human`. Present on all commands.
- `--blueprints <path>` — optional local blueprints directory layered on top of the bundled official blueprints. Present on `validate`, `generate`, `dry-run`, and `list-blueprints`.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0    | Success, no issues |
| 1    | Success with validation warnings |
| 2    | Validation errors present |
| 3    | Model parse failure |
| 4    | Generation failure |

---

## MCP Server

Executable: `modelhike-mcp` (target `ModelHikeMCP`, path `Sources/MCP/`)

Transport: **stdio** (launched as subprocess by Cursor/other MCP clients).

### Tool: modelhike/validate

```json
{
  "name": "modelhike/validate",
  "description": "Validate .modelhike model content and return structured diagnostics.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content to validate" }
    },
    "required": ["content"]
  }
}
```

### Tool: modelhike/generate

```json
{
  "name": "modelhike/generate",
  "description": "Generate code from validated .modelhike model content, persist it to disk, and return a structured file manifest.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": "Validated .modelhike DSL content" },
      "blueprint": { "type": "string", "description": "Blueprint name" },
      "outputPath": { "type": "string", "description": "Optional output directory; defaults to '<cwd>/modelhike-output' for inline content" }
    },
    "required": ["content", "blueprint"]
  }
}
```

### Tool: modelhike/dry-run

```json
{
  "name": "modelhike/dry-run",
  "description": "Preview generated files from validated .modelhike model content without persisting them.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": "Validated .modelhike DSL content" },
      "blueprint": { "type": "string", "description": "Blueprint name" }
    },
    "required": ["content", "blueprint"]
  }
}
```

### Tool: modelhike/inline-generate

```json
{
  "name": "modelhike/inline-generate",
  "description": "Generate code from inline .modelhike content and an inline blueprint JSON object.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content" },
      "inlineBlueprint": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "scripts": { "type": "object" },
          "templates": { "type": "object" },
          "folders": { "type": "object" },
          "modifiers": { "type": "object" }
        },
        "required": ["name", "scripts"]
      },
      "outputPath": { "type": "string", "description": "Optional output directory; when omitted, the tool returns a preview without persisting." }
    },
    "required": ["content", "inlineBlueprint"]
  }
}
```

### Tool: modelhike/explain

```json
{
  "name": "modelhike/explain",
  "description": "Explain the architecture represented by .modelhike model content.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content to explain" }
    },
    "required": ["content"]
  }
}
```

### Tool: modelhike/inspect

```json
{
  "name": "modelhike/inspect",
  "description": "Inspect one entity in a .modelhike model.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content" },
      "entity": { "type": "string", "description": "Entity name to inspect" }
    },
    "required": ["content", "entity"]
  }
}
```

### Tool: modelhike/what-depends-on

```json
{
  "name": "modelhike/what-depends-on",
  "description": "Show all entities that depend on a target entity. Optionally compute breaking changes for rename/remove operations.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content" },
      "entity": { "type": "string", "description": "Entity name to analyze" },
      "change": { "type": "string", "description": "Optional change kind: rename or remove" },
      "newName": { "type": "string", "description": "New name for rename operations" }
    },
    "required": ["content", "entity"]
  }
}
```

### Tool: modelhike/list-types

```json
{
  "name": "modelhike/list-types",
  "description": "List all type names declared in the model, organized by module and container.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content" }
    },
    "required": ["content"]
  }
}
```

### Tool: modelhike/fix

```json
{
  "name": "modelhike/fix",
  "description": "Auto-repair model diagnostics and return corrected model content.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content to fix" },
      "codes": { "type": "string", "description": "Optional comma-separated diagnostic codes to fix" }
    },
    "required": ["content"]
  }
}
```

### Tool: modelhike/preflight

```json
{
  "name": "modelhike/preflight",
  "description": "Pre-generation readiness check combining validate + blueprint checks.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "content": { "type": "string", "description": ".modelhike DSL content to check" },
      "blueprint": { "type": "string", "description": "Optional blueprint name to verify" }
    },
    "required": ["content"]
  }
}
```

### Tool: modelhike/list-blueprints

```json
{
  "name": "modelhike/list-blueprints",
  "description": "List all available ModelHike blueprints.",
  "inputSchema": {
    "type": "object",
    "properties": {}
  }
}
```

### Tool: modelhike/dsl-schema-in-markdown

```json
{
  "name": "modelhike/dsl-schema-in-markdown",
  "description": "Return the full canonical DSL documentation as markdown (three bundled spec files as JSON strings).",
  "inputSchema": {
    "type": "object",
    "properties": {}
  }
}
```

Structured content is a `DSLMarkdownSchemaResult` (`modelHikeDSL`, `codeLogicDSL`, `templateSoupDSL`).

### Cursor MCP Configuration

```json
{
  "mcpServers": {
    "modelhike": {
      "command": "/path/to/modelhike-mcp",
      "args": ["--blueprints", "/path/to/blueprints"],
      "transportType": "stdio"
    }
  }
}
```

`--blueprints` is optional here; the server already includes the official bundled blueprints from the `modelhike-blueprints` package dependency.

---

## AI Agent Workflow

This is the intended end-to-end flow when an AI agent uses the MCP tools:

1. **Developer states intent** — "I need a microservice for customer subscriptions with Stripe integration"
2. **AI calls `modelhike/dsl-schema-in-markdown`** (optional) to load the full DSL spec into context before drafting
3. **AI drafts a `.modelhike` model** from the natural language description
4. **AI calls `modelhike/validate`** with the draft content
5. **Engine returns structured diagnostics** — e.g. `W301: unresolved type StripeEvent`
6. **AI fixes the model** based on the diagnostic code and suggestions
7. **AI re-validates** — loops until `valid: true`
8. **AI calls `modelhike/explain`** — gets a structured architecture summary
9. **AI presents the summary** to the developer: "Here's the architecture I'm proposing..."
10. **Developer refines** — "Add a webhook handler for payment failures"
11. **AI modifies the model**, validates again
12. **AI optionally calls `modelhike/dry-run`** to preview the file tree without writing anything
13. **AI calls `modelhike/generate`** with the validated model and chosen blueprint
14. **Engine persists the generated output** and returns the generated file tree plus output directory

The feedback loop in steps 4-7 IS the init process. There is no separate `init` command — validation diagnostics guide the AI to produce a correct model iteratively.

---

## File Structure

```
modelhike-smart-cli/
├── Package.swift                          # Swift 6.2 tools manifest, Swift 6-style code
├── AGENTS.md                              # THIS FILE — keep updated
├── Sources/
│   ├── ModelHikeKit/                      # Shared engine library
│   │   ├── ModelHikeEngine.swift          # Central orchestrator
│   │   ├── ModelInput.swift               # Input enum (content/file/directory)
│   │   ├── DiagnosticExtractor.swift      # Extracts diagnostics from DebugRecorder
│   │   ├── SnapshotMapper.swift           # Maps ModelSnapshot to ExplanationResult
│   │   ├── DependencyWalker.swift         # Reverse dependency graph traversal
│   │   ├── DSLSchemaExport.swift           # typealias ModelHikeDSLSchema (upstream)
│   │   └── Results/
│   │       ├── ValidationResult.swift
│   │       ├── GenerationResult.swift
│   │       ├── ExplanationResult.swift
│   │       ├── InspectionResult.swift
│   │       ├── DependencyResult.swift
│   │       ├── TypeListResult.swift
│   │       ├── FixResult.swift
│   │       ├── PreflightResult.swift
│   │       ├── BlueprintListResult.swift
│   │       ├── DSLMarkdownSchemaResult.swift
│   │       └── Diagnostic.swift
│   ├── CLI/                               # modelhike executable
│   │   ├── ModelHikeCLI.swift             # @main, root ParsableCommand
│   │   ├── Commands/
│   │   │   ├── ValidateCommand.swift
│   │   │   ├── GenerateCommand.swift
│   │   │   ├── InlineGenerateCommand.swift
│   │   │   ├── DryRunCommand.swift
│   │   │   ├── ExplainCommand.swift
│   │   │   ├── InspectCommand.swift
│   │   │   ├── WhatDependsOnCommand.swift
│   │   │   ├── ListTypesCommand.swift
│   │   │   ├── FixCommand.swift
│   │   │   ├── PreflightCommand.swift
│   │   │   ├── ListBlueprintsCommand.swift
│   │   │   └── SchemaInMarkdownCommand.swift
│   │   ├── Formatting/
│   │   │   └── OutputFormatter.swift      # JSON and human-readable formatters
│   │   └── Shared/
│   │       ├── InputResolver.swift        # --input flag → ModelInput
│   │       ├── InlineInputResolver.swift  # inline flags → ModelInput + InlineBlueprintSnapshot
│   │       ├── ExitCodes.swift
│   │       └── CommandSupport.swift       # Shared command exit/error helpers
│   └── MCP/                               # modelhike-mcp executable
│       ├── ModelHikeMCPServer.swift        # @main, stdio Server setup
│       ├── ToolDefinitions.swift           # Tool schemas for all 12 tools
│       └── ToolRouter.swift               # Dispatches CallTool → engine
├── DevTester_MCP/                          # MCP smoke-test target files
│   ├── README.md
│   └── Sources/
│       ├── DevTesterMCPCommand.swift      # Configurable smoke-test CLI
│       ├── SmokeRunner.swift              # MCP client flow + assertions
│       └── ChildProcessTransport.swift    # Launches modelhike-mcp over stdio
├── Tests/
│   └── ModelHikeKitTests/                 # Swift Testing suites (`import Testing`)
│       ├── ValidateTests.swift
│       ├── ExplainTests.swift
│       ├── BlueprintsTests.swift
│       ├── InlineGenerateTests.swift
│       ├── ModelSupportFilesTests.swift
│       └── SchemaTests.swift
└── docs/
    ├── README.md                          # Overview, install, quick start
    ├── cli-reference.md                   # Full CLI command reference
    ├── mcp-reference.md                   # MCP tool schemas + examples
    ├── smart-cli-philosophy.md            # Design principles, AI agent patterns
    └── architecture.md                    # Internal architecture
```

---

## Conventions

### Swift

- **Swift 6.x**, strict concurrency. All public types are `Sendable`.
- Keep the codebase compatible with the locally-buildable Swift 6.2 toolchain unless the environment is upgraded.
- All result types are `Codable & Sendable` — they must serialize cleanly to JSON.
- Use structured concurrency (`async`/`await`). The ModelHike core uses actors extensively (`AppModel`, `LoadContext`, etc.).
- No force unwraps. No `try!`. All errors must be caught and converted to structured diagnostics.
- Prefer value types (`struct`, `enum`) for all result types. The engine itself is a `struct`.

### Output

- CLI default output is **human-readable text**.
- `--format json` produces one top-level JSON object, pretty-printed.
- MCP tools return structured content plus a minimal text content payload.
- Never print to stdout except the final result. Use stderr for progress/debug info if needed.

### Error Handling

- Parse failures (malformed DSL) should be caught and returned as diagnostics, not crashes.
- Pipeline errors should be caught by the engine, wrapped in the appropriate result type with `valid: false` or error diagnostics.
- The CLI translates result states to exit codes. The MCP server returns `isError: true` content.

### Testing

- Use **Swift Testing** (`import Testing`) for all new tests. Do not add new `XCTestCase` suites.
- Prefer `@Test` and `#expect(...)` / `#require(...)` over XCTest assertions.
- Test against inline model content using `ModelInput.content(...)`.
- Validate that known-bad models produce expected diagnostic codes.
- Validate that known-good models produce `valid: true`.
- Test human output format doesn't break when diagnostics contain special characters.
- **Process hygiene before `swift test`:** this workspace has repeatedly accumulated stale/orphaned SwiftPM test processes (`swift test`, `swiftpm-testing-helper`, and lingering `*.xctest` helpers) that can make later runs hang after `Build complete!` or report that another SwiftPM instance is already using `.build`.
- Before starting a new test run, first check existing terminals and inspect running processes. If an older test run is clearly stale or orphaned, kill only the specific stale PIDs before rerunning.
- If a fresh `swift test` appears stuck with no new output for an unusual amount of time, inspect the process list for orphaned `swiftpm-testing-helper` children even when the original shell command has already exited, then clean those up and retry.

### Dependencies

| Package | Version | Target(s) | Purpose |
|---------|---------|-----------|---------|
| `modelhike/modelhike` | branch `main` | ModelHikeKit | Core pipeline, parser, validation, generation |
| `modelhike/modelhike-blueprints` | branch `main` | ModelHikeKit, ModelHikeCLI, ModelHikeMCP | Bundled official blueprints (`OfficialBlueprintFinder`) |
| `apple/swift-argument-parser` | from 1.7.1 | ModelHikeCLI, DevTester_MCP | CLI argument parsing |
| `modelcontextprotocol/swift-sdk` | from 0.12.0 | ModelHikeMCP, DevTester_MCP | MCP server/client, stdio transport |
| `apple/swift-log` | from 1.11.0 | DevTester_MCP | Structured logging for MCP smoke tests |

### When Adding a New Command

1. Add the engine method to `ModelHikeEngine` with appropriate pipeline phases
2. Add a result type in `Sources/ModelHikeKit/Results/`
3. Add a CLI subcommand in `Sources/CLI/Commands/` and register it in `ModelHikeCLI.swift`
4. Add an MCP tool definition in `ToolDefinitions.swift` and a case in `ToolRouter.swift`
5. Add formatter support in `OutputFormatter.swift` for both JSON and human modes
6. Update this AGENTS.md: command table, MCP tool schema, file structure
7. Update `docs/cli-reference.md` and `docs/mcp-reference.md`

---

## Upstream: ModelHike Core Gotchas

Things an agent must know when working with the ModelHike library:

- **`AppModel` is an actor.** All property access requires `await`. Same for `C4Container`, `C4Component`, `DomainObject`, `Property`, etc.
- **The engine uses partial upstream pipelines.** `Pipeline.ws.context` is used to attach an `InlineModelLoader`, and the CLI assembles command-specific phase subsets with `LoadModelsPass`, `HydrateModelsPass`, `PassDownAndProcessAnnotationsPass`, `ValidateModelsPass`, and `GenerateCodePass`.
- **Diagnostics are not thrown.** Upstream validation/generation phases record diagnostics into the debug log. You must attach a `DefaultDebugRecorder` to capture them.
- **`config.flags.printDiagnosticsToStdout`** must be `false` for the smart CLI — we capture diagnostics programmatically, not via print statements.
- **Blueprint resolution** uses `OfficialBlueprintFinder()` (from `modelhike-blueprints` package) by default. Optionally, `config.localBlueprintsPath` adds local filesystem blueprints on top.
- **`ModelSnapshot`** is built by `DefaultDebugRecorder.captureModel(_:)`. It produces a `Codable` tree of containers/modules/objects/properties/methods — ideal for the `explain` command.
- **`PipelineState.generationSandboxes`** contains the in-memory generated files after Render but before Persist. Each `GenerationSandbox` has a file tree that can be enumerated.
- **The common model file** (`common.modelhike`) and optional `main.tconfig` are still resolved explicitly by the engine for file/directory inputs, then supplied to `InlineModelLoader`.
- **All result types carry a `diagnostics` array.** Every command returns diagnostics, not just `validate`. Agents should always check the diagnostics field.

---

## Maintenance Checklist

When you modify this codebase, verify:

- [ ] `AGENTS.md` is updated if architecture, APIs, commands, or conventions changed
- [ ] `docs/` files are updated for any user-facing changes
- [ ] All result types remain `Codable & Sendable`
- [ ] New commands are registered in both CLI and MCP
- [ ] Exit codes are consistent with the documented table
- [ ] JSON output is valid and parseable
- [ ] Human output is readable without relying on JSON structure
