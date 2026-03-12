# ModelHike — Comprehensive Project Analysis

> **Purpose of this file:** A thorough, durable reference for any agent, engineer, or tool that needs to understand the project's current state without having to re-read every source file. Keep this file updated when making structural changes.

---

## Table of Contents

1. [What ModelHike Is](#1-what-modelhike-is)
2. [Repository Layout](#2-repository-layout)
3. [Swift Package](#3-swift-package)
4. [The ModelHike DSL](#4-the-modelhike-dsl)
5. [Source Module Breakdown](#5-source-module-breakdown)
6. [The 6-Phase Pipeline](#6-the-6-phase-pipeline)
7. [Domain Model Objects](#7-domain-model-objects)
8. [Template Engine — TemplateSoup + SoupyScript](#8-template-engine--templatesoup--soupyscript)
9. [Blueprint System](#9-blueprint-system)
10. [Workspace, Context, and Sandbox](#10-workspace-context-and-sandbox)
11. [DevTester Executable](#11-devtester-executable)
12. [Visual Debugging](#12-visual-debugging)
13. [Tests](#13-tests)
14. [Playground](#14-playground)
15. [Current Project State & Known Gaps](#15-current-project-state--known-gaps)
16. [Key Conventions & Patterns](#16-key-conventions--patterns)
17. [Glossary](#17-glossary)

---

## 1. What ModelHike Is

ModelHike is an open-source **code-generation toolchain** written in Swift 6. It takes plain-text, Markdown-flavoured **software models** (`.modelhike` or `.dsl.md` files) and generates production-grade, framework-specific source code, documentation, and architecture diagrams.

The core philosophy:

- **Single source of truth** — `.modelhike` files describing architecture (C4 model), data schemas, validation rules, and API surface.
- **Deterministic builds** — same model + same templates = identical output, every time. CI-safe.
- **AI optional** — AI can bootstrap or suggest models, but the generation pipeline is template-driven and fully controllable.
- **Zero external Swift dependencies** — the library is self-contained.

The value proposition is the elimination of hand-written boilerplate: entities, repositories, controllers, services, DTOs, tests, and API docs are all generated from the model.

---

## 2. Repository Layout

```
modelhike/
├── Package.swift               # Swift Package definition
├── README.md                   # Public-facing docs (aspirational; some features not yet implemented)
├── AGENTS.md                   # This file — living project analysis
├── .ai/
│   └── brainstorm/
│       └── debug-console-brainstorm.md  # Archived design/brainstorm notes for AI-assisted doc work
├── CREDITS.md
├── LICENSE                     # MIT
├── SECURITY.md
│
├── Sources/                    # Main Swift library (target: ModelHike)
│   ├── _Common_/               # Foundation utilities, file I/O, extensions
│   ├── Debug/                  # DebugRecorder, DebugSession, DebugEvent, RenderedOutputSnapshot, etc.
│   ├── Modelling/              # DSL parser + in-memory domain model
│   ├── Scripting/              # SoupyScript template scripting engine
│   ├── CodeGen/                # TemplateSoup renderer + Blueprint loading
│   ├── Workspace/              # Context, Sandbox, expression evaluator
│   └── Pipelines/              # 6-phase pipeline orchestrator
│
├── DevTester/                  # Executable target for development runs
│   ├── DevMain.swift           # Entry point; runs codegen pipeline (or debug mode with --debug)
│   ├── Environment.swift       # Hardcoded dev/prod path configs
│   ├── DebugServer/            # DebugHTTPServer, HTTPTypes
│   └── Assets/                 # debug-console.html (browser UI)
│
├── Tests/                      # Test suites
│
├── DSL/
│   ├── modelHike.dsl.md        # Full DSL specification (Beginner → Pro guide)
│   └── codelogic.dsl.md        # Fenced method-body logic block syntax reference
│
├── Docs/
│   ├── documentation.md        # Product documentation outline (partially written)
│   ├── ADRs.md                 # Architecture Decision Records (minimal)
│   ├── debug/
│   │   ├── DEBUGGING.md        # Developer debugging guide: flags, hooks, in-template debugging
│   │   └── VISUALDEBUG.md      # Visual debugging system: architecture, data flow, troubleshooting
│   ├── modelHike.brand.md      # Brand guide
│   ├── quickstart.md           # Quickstart guide
│   └── old-detailed-readme.md  # Archived old README
│
└── _Playground/                # gitignored — local dev testing only, never committed
```

---

## 3. Swift Package

**File:** `Package.swift` (swift-tools-version: 6.0)

| Property | Value |
|---|---|
| Package name | `ModelHike` |
| Swift tools version | 6.0 (strict concurrency enabled) |
| Platforms | macOS 13+, iOS 16+, tvOS 13+, watchOS 6+ |
| Products | `ModelHike` (library), `DevTester` (executable) |
| External dependencies | **None** — zero-dependency design |

**Targets:**

| Target | Type | Path |
|---|---|---|
| `ModelHike` | Library | `Sources/` |
| `DevTester` | Executable | `DevTester/` |
| `ModelHikeTests` | Test | `Tests/` |

The entire `Sources/` tree is compiled as a single `ModelHike` library target. There is no source-level separation between sub-modules from the Swift compiler's perspective; the sub-directories are organizational only.

---

## 4. The ModelHike DSL

**Spec files:** `DSL/modelHike.dsl.md` (full DSL), `DSL/codelogic.dsl.md` (method logic fence syntax)

The DSL is a Markdown-flavoured text format.

**Canonical file extension: `.modelhike`** — this is what `ModelConstants.ModelFile_Extension` defines and what `LocalFileModelLoader` exclusively scans for. Any file in `basePath` with extension `.modelhike` (except `common.modelhike`) is loaded as a model file.

**Special file: `common.modelhike`** — if present in `basePath`, it is loaded first and its types are stored in `model.commonModel` (shared across all containers, used for mixins like `Audit`, `CodedValue`, `Reference`, etc.).

**Generation config: `main.tconfig`** — if present in `basePath` (the model folder), loaded during **Phase 2 (Load)** by `LocalFileModelLoader.loadGenerationConfigIfAny()` via `ConfigFileParser`. Parses key-value pairs (e.g., `API_StartingPort = 3000`) into `LoadContext.variables`. These variables are available when `main.ss` executes in Phase 5. This is the pre-configuration step that runs before the blueprint entry point.

### 4.1 Structural Hierarchy

```
Container  (===...===)
  └─ Module  (=== Name === or === Name ====)
       └─ SubModule  (extra = closing fence)
            ├─ Class / Entity  (Name \n underline of =)
            ├─ DTO             (Name \n /===/  underline)
            ├─ UIView          (Name \n ~~~~ underline)
            └─ Method          (~ prefix inside a class)
```

> **Syntax reference:** All DSL syntax — property prefixes, type names, array notation, attribute/annotation/tag grammar, UIView syntax, method syntax, API protocol options, and the `(backend)` attribute convention — is documented in [`DSL/modelHike.dsl.md`](DSL/modelHike.dsl.md). Fenced method-body logic block syntax (fence styles, depth rules, all statement keywords) is documented in [`DSL/codelogic.dsl.md`](DSL/codelogic.dsl.md). Those files are the single source of truth. **Update them when any syntax changes; do not duplicate syntax here.**

---

## 5. Source Module Breakdown

### `Sources/_Common_/`

Foundation-level utilities shared across all other modules.

| Sub-folder | Contents |
|---|---|
| `Document/` | `Document`, `Node`, `Tag`, `Attribute`, `Event`, `Renderable` — generic document-tree types |
| `Errors/` | `ParsingError`, `EvaluationError`, `ErrorWithInfo` — public error hierarchy |
| `Extensions/` | Swift extensions on `String`, `Array`, `Dictionary`, `Date`, `Data`, `Regex`, `Any+Optional`, `Defaultable`, `StringConvertible`, `Misc` |
| `FileGen/` | `FileGenerator`, `InputFile/Folder`, `OutputFile/Folder`, `LocalFolder+File`, `Path`, `SystemFolders`; file type protocols: `FileToCopy`, `StaticFile`, `StaticFolder`, `RenderedFolder`, `TemplateRenderedFile`, `PlaceHolderFile`, `OutputDocumentFile` |
| `RegEx/` | `CommonRegEx` — shared regex patterns |
| `Sendable/` | `AsyncSequence`, `CheckSendable`, `SendableDebug` — Swift 6 concurrency helpers |
| `ThirdParty/` | `Codextended` (embedded, MIT), `StringWrapper`, `pluralized` |
| `Utils/` | `ResultBuilder`, `RuntimeReflection`, `ShellExecute` |

### `Sources/Modelling/`

DSL parsing and the in-memory domain model.

```
Modelling/
├── ModelFileParser.swift       # Top-level DSL file parser (dispatches to sub-parsers)
├── _Base_/
│   ├── Annotation/             # Annotation parsing, processing, constants, types
│   ├── AttachedSections/       # Sections attached to model elements
│   ├── C4Component/            # C4Component + C4ComponentList (actors)
│   ├── C4Container/            # C4Container + C4ContainerList (actors)
│   ├── CodeElement/            # CodeMember, CodeObject, MethodObject, Property, TypeInfo
│   ├── Loader/                 # InlineModelLoader, LocalFileModelLoader, ModelRepository
│   ├── RegEx/                  # ModelRegEX — DSL-specific regex patterns
│   ├── System/                 # C4System
│   ├── Artifact.swift          # Artifact protocol + ArtifactKind enum
│   ├── Imports.swift
│   ├── ModelConfigConstants.swift
│   ├── ModelConstants.swift    # `*`, `-`, `.` prefix constants
│   ├── ModelErrors.swift
│   ├── ModelSpace.swift        # Root model object: containers + modules
│   ├── ParserUtil.swift        # Shared parsing helpers
│   └── TagConstants.swift
├── API/
│   ├── API+Extension.swift     # APIState, GenericAPI, API protocol, APIType enum, QueryParam types
│   ├── APIList.swift           # Collection of APIs
│   ├── APISectionParser.swift  # Parses `# APIs ... #` blocks
│   ├── CustomAPIs.swift        # Custom API operation parsing
│   └── WebService.swift        # WebService_MonoRepo wrapper
├── Container+Module/
│   ├── ContainerMember.swift
│   ├── ContainerParser.swift   # Parses `=== Name ===` fences
│   ├── ModuleParser.swift      # Parses `=== Module ===`
│   └── SubModuleParser.swift   # Parses `=== SubModule ====`
├── Domain/
│   ├── DerivedProperty.swift
│   ├── DomainObject.swift      # Class/Entity actor
│   ├── DomainObjectParser.swift
│   ├── DtoObject.swift         # DTO actor
│   └── DtoObjectParser.swift
└── UI/
    ├── UIView.swift            # UIView actor + UIObject protocol
    └── UIViewParser.swift
```

**Key types:**

- `ModelFileParser` (actor) — main entry point; dispatches to `ContainerParser`, `ModuleParser`, `SubModuleParser`, `DomainObjectParser`, `DtoObjectParser`, `UIViewParser`.
- `ModelSpace` (actor) — root model: holds `C4ContainerList` + `C4ComponentList`.
- `C4Container` (actor) — `name`, `givenname`, `containerType` (unknown/microservices/webApp/mobileApp), `C4ComponentList`, `unresolvedMembers`.
- `C4Component` (actor) — module; holds `CodeObject`s (domain objects, DTOs, UIViews) + submodules.
- `DomainObject` (actor) — class with `[CodeMember]` (properties + methods), `mixins`, `attachedSections`, `Annotations`, `Attributes`, `Tags`. `properties` returns members that are `Property`; `methods` returns members that are `MethodObject`.
- `MethodObject` (actor) — `name`, `givenname`, `parameters: [MethodParameter]`, `returnType: TypeInfo`, `logic: CodeLogic?`, `tags`. Parsed from `~ methodName(param: Type) : ReturnType` (tilde-prefix) or `methodName(...)\n------` (setext) lines. An optional fenced logic block (` ``` `, `'''`, or `"""` — 3+ chars, opening and closing must match) may follow a tilde-prefix method; setext methods use `---` as the closing fence.
- `DtoObject` (actor) — read-model; fields reference parent types.
- `UIView` (actor) — UI component; `dataType = .ui`.
- `Property` (actor) — `name`, `givenname`, `type: TypeInfo`, `required: RequiredKind`, `arrayMultiplicity: MultiplicityKind`, `isUnique`, `isObjectID`, `isSearchable`, `attribs`, `tags`.
- `PropertyKind` (enum) — full type system (see §4.3).
- `TypeInfo` — `kind: PropertyKind`, `isArray: Bool`; helpers `isObject()`, `isNumeric`, `isDate`, `isReference()`, etc.
- `APIType` (enum) — create, update, delete, getById, list, listByCustomProperties, getByCustomProperties, associate, deassosiate, activate, deactivate, pushData, pushDataList, getByUsingCustomLogic, listByUsingCustomLogic, mutationUsingCustomLogic.
- `ArtifactKind` (enum) — container, component, entity, dto, cache, apiInput, embeddedType, valueType, api, ui, unKnown.

### `Sources/Pipelines/`

The 6-phase pipeline orchestrator.

```
Pipelines/
├── Pipeline.swift          # Pipeline struct; runs phases sequentially; PipelineState actor
├── Pipelines.swift         # Pre-built pipeline presets: .codegen, .content, .empty
├── PipelineConfig.swift    # OutputConfig protocol + PipelineConfig struct
├── PipelinePass.swift      # Protocol hierarchy for passes
├── PipelinePhase.swift     # Phase protocol
├── PipelineErrorPrinter.swift
├── 1. Discover/
│   ├── Discover.swift      # Factory: Discover.models()
│   └── DiscoverModels.swift
├── 2. Load/
│   ├── Load.swift          # Factory: Load.models(), Load.contentsFrom()
│   ├── LoadModels.swift
│   ├── LoadPages.swift
│   ├── LoadTemplates.swift
│   └── ContentFromFolder.swift
├── 3. Hydrate/
│   ├── Hydrate.swift       # Factory: Hydrate.models(), Hydrate.annotations()
│   ├── HydrateModels.swift # Port assignment, dataType classification
│   └── PassDownAndProcessAnnotations.swift
├── 4. Transform/
│   ├── Transform.swift
│   └── Plugins.swift
├── 5. Render/
│   ├── Render.swift        # Factory: Render.code()
│   ├── GenerateCodePass.swift  # CURRENTLY HARDCODES blueprint = "api-nestjs-monorepo"
│   └── DebugRenderer.swift
└── 6. Persist/
    ├── Persist.swift       # Factory: Persist.toOutputFolder()
    └── GenerateOutputFolders.swift
```

**Pre-built pipelines** (`Pipelines.swift`):

```swift
Pipelines.codegen  // Discover → Load → Hydrate (models + annotations) → Render → Persist
Pipelines.content  // Load (contents + pages + templates)
Pipelines.empty    // No passes — useful for string-rendering tests
```

### `Sources/CodeGen/`

The template rendering engine.

```
CodeGen/
├── TemplateSoup/
│   ├── TemplateSoup.swift          # Main renderer actor; TemplateRenderer protocol
│   ├── TemplateSoupParser.swift
│   ├── TemplateEvaluator.swift     # Evaluates a Template object against Context
│   ├── _Base_/
│   │   ├── Blueprints/             # Blueprint protocol; LocalFile/Resource finders & loaders; BlueprintAggregator
│   │   ├── Templates/              # Template protocol; LocalFileTemplate, LocalFilesetTemplate, StringTemplate
│   │   └── SpecialFolderNames.swift / TemplateConstants.swift
│   └── ContentLine/
│       ├── ContentLine.swift       # Line protocol
│       ├── ContentHandler.swift
│       ├── TextContent.swift       # Plain text
│       ├── PrintExpressionContent.swift  # {{ expression }}
│       ├── InlineFunctionCallContent.swift
│       └── EmptyLine.swift
└── MockData/
    ├── MockData_Generator.swift
    ├── SampleJson.swift
    └── SampleQueryString.swift
```

`TemplateSoup` is the central actor for rendering. It:
- Loads templates and scripts via a `Blueprint` (pluggable source)
- Executes scripts via `ScriptFileExecutor`
- Evaluates templates via `TemplateEvaluator`
- Manages `GenerationContext` snapshots (push/pop) for scoped variable isolation
- Provides `forEach(forInExpression:)` for programmatic loop driving

The special entry-point file in a blueprint is **`main.ss`** — `TemplateConstants.MainScriptFile = "main"` + `TemplateConstants.ScriptExtension = "ss"`. Before `main.ss` is invoked, `main.tconfig` from the model folder is loaded during Phase 2 (Load), injecting variables into the context that `main.ss` can reference.

### `Sources/Scripting/`

The SoupyScript DSL interpreter.

```
Scripting/
├── SoupyScript/
│   ├── ScriptParser.swift
│   ├── SoupyScriptParser.swift
│   ├── Containers/
│   │   └── TemplateFunction.swift  # User-defined template functions
│   ├── Libs/
│   │   ├── DefaultModifiersLibrary.swift   # String, math, array, dict, date modifiers
│   │   ├── DefaultOperatorsLibrary.swift   # and, or, not, comparisons, arithmetic
│   │   ├── StatementsLibrary.swift         # Registry of all statement types
│   │   └── ModifierLibs/
│   │       ├── GenerationLib.swift
│   │       ├── MockDataLib.swift
│   │       ├── ModelLib.swift              # Model introspection: type checking, property access
│   │       └── Modifiers-LangSpecific/
│   │           ├── TypescriptLib.swift     # typename, default-value
│   │           ├── JavaLib.swift
│   │           ├── GraphQLLib.swift
│   │           └── MongoDB_TypescriptLib.swift
│   ├── Stmts/                              # All statement implementations
│   │   ├── For.swift       AnnnounceStmt.swift   ConsoleLog.swift
│   │   ├── If.swift        CopyFile.swift         CopyFolder.swift
│   │   ├── FunctionCall.swift   FillAndCopyFile.swift
│   │   ├── RenderFile.swift     RenderFolder.swift
│   │   ├── RunShellCmd.swift    SetStr.swift       SetVar.swift
│   │   ├── Spaceless.swift      Stop.swift         ThrowError.swift
│   │   └── UnIdentifiedStmt.swift
│   └── Symbols/
│       ├── Modifiers/  # Modifier, ModifierInstance, Modifiers collection, CreateModifierHelper
│       └── Operators/  # Operator, CreateOperatorHelper
├── Wrappers/                               # Script-accessible wrappers around model objects
│   ├── APIWrap.swift
│   ├── C4ComponentWrap.swift
│   ├── C4ContainerWrap.swift
│   ├── CodeObjectWrap.swift
│   ├── DataMockWrap.swift
│   ├── Loop.swift                          # @loop variable in for loops
│   └── UIObjectWrap.swift
└── _Base_/
    ├── LocalScriptFile.swift
    ├── ScriptFile.swift
    ├── ScriptFileExecutor.swift            # Executes a parsed script
    ├── SoupyScriptStmtContainerList.swift
    ├── TemplateStmtContainer.swift
    ├── Wrapper+DynamicMemberLookup.swift
    ├── Parsing/
    │   ├── FrontMatter.swift
    │   ├── LineParser.swift
    │   ├── ParsedInfo.swift
    │   └── ParserDirective.swift   TemplateSoup_ParsingError.swift
    └── Stmts+Config/
        ├── BlockOrLineTemplateStmt+Config.swift
        ├── BlockTemplateStmt+Config.swift
        ├── LineTemplateStmt+Config.swift
        └── MultiBlockTemplateStmt+Config.swift
```

### `Sources/Workspace/`

The execution context and sandbox.

```
Workspace/
├── Workspace.swift             # Public facade (actor): config, model, sandboxes, render
├── Config/
│   └── ConfigFileParser.swift  # Parses .tconfig files (key=value pairs)
├── Context/
│   ├── CallStack.swift
│   ├── CodeGenerationEvents.swift  # Event hooks: onBeforeRenderTemplateFile, onBeforeRenderFile, etc.
│   ├── Context.swift
│   ├── ContextState + Symbol.swift
│   ├── DebugUtils.swift
│   ├── GenerationContext.swift     # Extends LoadContext for render phase
│   ├── LoadContext.swift           # Context during load phase
│   ├── ModelSymbols.swift
│   ├── ObjectAttributeManager.swift
│   ├── SnapshotStack.swift
│   ├── TemplateFunctionMap.swift
│   ├── TemplateSoupSymbols.swift   # Registry: modifiers + operators + statements
│   └── WorkingMemory.swift
├── Evaluation/
│   ├── ExpressionEvaluator.swift
│   ├── RegularExpressionEvaluator.swift  # Boolean expression parser (and/or/not/comparisons)
│   └── TemplateSoup_EvaluationError.swift
└── Sandbox/
    ├── AppModel.swift                    # Holds ModelSpace + commonModel
    ├── CodeGenerationSandbox.swift       # Main generation actor (GenerationSandbox protocol)
    ├── ParsedTypesCache.swift
    └── Sandbox.swift                     # Sandbox protocol
```

---

## 6. The 6-Phase Pipeline

```
Discover ──► Load ──► Hydrate ──► Transform ──► Render ──► Persist
```

Each phase is a `PipelinePhase` that holds a list of `PipelinePass` implementations. Passes are composable — you can build custom pipelines using the `@PipelineBuilder` DSL.

### Phase 1 — Discover

- `DiscoverModels` — walks `basePath` looking for `.modelhike` files and registers them in `LoadContext`.

### Phase 2 — Load

- `LoadModels` — for each discovered file, runs `ModelFileParser` which dispatches to sub-parsers. Populates `ModelSpace` with `C4Container`s, `C4Component`s, `DomainObject`s, `DtoObject`s, `UIView`s.
- `LoadPages`, `LoadTemplates`, `ContentFromFolder` — optional passes for non-codegen content pipelines.

### Phase 3 — Hydrate

- `HydrateModels` — post-load refinements:
  - Assigns sequential port numbers (starting at 3001) to each microservice.
  - Classifies `DomainObject` data types: `entity` (has `id`/`_id`), `cache` (name ends with `Cache`), `apiInput` (name ends with `Input`), `embeddedType` (otherwise).
  - Classifies `DtoObject` data types: `dto` or `apiInput`.
- `PassDownAndProcessAnnotations` — resolves annotation inheritance and cascades annotations down the model hierarchy.

### Phase 4 — Transform

- Currently a no-op placeholder. Intended for plugins/transformation passes.

### Phase 5 — Render

- `GenerateCodePass` — the main code generation pass:
  1. Selects a blueprint (`api-nestjs-monorepo` is currently hardcoded).
  2. Loads language-specific modifier symbols (TypeScript + MongoDB for NestJS; Java for Spring Boot).
  3. Creates a `CodeGenerationSandbox`.
  4. Calls `sandbox.generateFilesFor(container:)` which:
     - Sets `@container` and `@mock` template variables.
     - Renders the blueprint's `Root/` special folder.
     - Executes `main.ss` (the blueprint's entry-point SoupyScript file).

### Phase 6 — Persist

- `GenerateOutputFolders` — iterates all `OutputFolder`s and `OutputFile`s queued during Render, writes them to disk at `config.output` path.

---

## 7. Domain Model Objects

### Object Hierarchy

```
Artifact (protocol)
├── ArtifactHolder (protocol) → C4Container, C4Component
├── CodeObject (protocol) → DomainObject, DtoObject
│   └── CodeMember (protocol) → Property, MethodObject
└── UIObject (protocol) → UIView
```

### `C4Container` (actor)

| Field | Type | Description |
|---|---|---|
| `name` | String | Normalised (variable-name safe) |
| `givenname` | String | Original human-readable name |
| `containerType` | `ContainerKind` | unknown / microservices / webApp / mobileApp |
| `components` | `C4ComponentList` | Modules contained |
| `unresolvedMembers` | `[ContainerModuleMember]` | Pending module references |
| `attribs` | `Attributes` | |
| `tags` | `Tags` | |
| `annotations` | `Annotations` | |

### `C4Component` (actor) — Module

Holds `DomainObject`s, `DtoObject`s, `UIView`s. Has `submodules`. Inherits from parent modules via `mixins`.

### `DomainObject` (actor) — Class/Entity

| Field | Type |
|---|---|
| `name` / `givenname` | String |
| `members` | `[CodeMember]` (Property + MethodObject) |
| `mixins` | `[CodeObject]` (resolved parent classes) |
| `attachedSections` | `AttachedSections` |
| `attached` | `[Artifact]` (APIs attached to this object) |
| `dataType` | `ArtifactKind` |
| `attribs` / `tags` / `annotations` | Metadata |

### `Property` (actor)

| Field | Type | Notes |
|---|---|---|
| `name` / `givenname` | String | |
| `type` | `TypeInfo` | kind + isArray |
| `required` | `RequiredKind` | `yes` (`*`) / `no` (`-` or `_`) / `conditional` (`*?`) |
| `arrayMultiplicity` | `MultiplicityKind` | noBounds / lowerBound / bounded |
| `isUnique` | Bool | |
| `isObjectID` | Bool | |
| `isSearchable` | Bool | |
| `attribs` / `tags` | Metadata | Validation rules, etc. |

### `APIType` enum

```
create, update, delete, getById, list,
listByCustomProperties, getByCustomProperties,
associate, deassosiate, activate, deactivate,
pushData, pushDataList,
getByUsingCustomLogic, listByUsingCustomLogic, mutationUsingCustomLogic
```

---

## 8. Template Engine — TemplateSoup + SoupyScript

### 8.1 TemplateSoup (template renderer)

`TemplateSoup` is the core rendering actor. It accepts a `Blueprint` (template source) and a `GenerationContext` and exposes:

- `renderTemplate(fileName:data:with:)` — render a named template file
- `renderTemplate(string:data:with:)` — render an inline template string
- `runScript(fileName:data:with:)` — run a SoupyScript file
- `startMainScript(with:)` — run the blueprint's `main.ss` entry-point script
- `forEach(forInExpression:renderClosure:)` — programmatic loop

> **Template + scripting syntax reference:** All TemplateSoup and SoupyScript syntax — `{{ }}` print expressions, file-type prefix rules (`.ss` vs `.teso`), statement reference, front matter, built-in template variables, modifiers, and operators — is documented in [`DSL/templatesoup.dsl.md`](DSL/templatesoup.dsl.md). That file is the single source of truth. **Update `DSL/templatesoup.dsl.md` when any syntax changes; do not duplicate syntax here.**

---

## 9. Blueprint System

A **Blueprint** is a named folder inside `localBlueprintsPath` containing `.teso` template files, static files, subfolder groups, and a `main.ss` entry-point SoupyScript. The engine renders it against a loaded model to produce the output codebase.

### Blueprint Sources

| Type | Class | Description |
|---|---|---|
| Local filesystem | `LocalFileBlueprint` | Loads from an absolute path (the external `modelhike-blueprints` repo) |
| Swift resources | `ResourceBlueprint` | Loads from embedded Swift package resources |
| Aggregated | `BlueprintAggregator` | Merges multiple blueprint sources |

### Current Blueprints

Two blueprints live in `modelhike-blueprints/Sources/Resources/blueprints/`. `GenerateCodePass` currently hardcodes:

```swift
let blueprint = "api-nestjs-monorepo"    // ACTIVE
// let blueprint = "api-springboot-monorepo"  // commented out
```

---

### Special Blueprint Folders

- **`_root_/`** — static files (and `.teso` templates) that are copied/rendered into the output root. Contains Dockerfile, env files, config files, etc.
- There is **no** `Root/` folder in the actual blueprints; `_root_/` is the convention used.
- **`_modifiers_/`** — blueprint-local modifier definitions. Each `.teso` file in this folder is registered as a named `Modifier`. See §9.1 below for the front-matter schema.

### 9.1 Blueprint-Defined Modifiers (`_modifiers_/`)

Any `.teso` file placed in the blueprint's `_modifiers_/` folder is automatically loaded and registered as a modifier before `main.ss` runs. The modifier name is the filename without the `.teso` extension.

**Front-matter schema** (YAML key:value pairs between `---` fences):

```
---
input: value          # variable name the piped value is bound to in the template
type: String          # expected input type: String | Double | Bool | Array | Object | Any
params: from, to      # (optional) positional argument names, comma-separated
---
```

- All three keys are optional. Defaults: `input = "value"`, `type = Any`, no params.
- If `params` is absent, the modifier is registered as a **no-arg** modifier: `{{ value | myModifier }}`.
- If `params` is present, the modifier is registered as a **with-args** modifier: `{{ value | myModifier(arg1, arg2) }}`.
- The template body renders to a `String`. Normal TemplateSoup syntax (`:if`, `:for`, `{{ expr }}`, etc.) is fully available.
- Type mismatch at call time throws `modifierCalledOnwrongType`.

**Example — no-arg modifier (`_modifiers_/javaType.teso`):**

```teso
---
input: prop
type: Object
---
:if prop.type == "String"
String
:end-if
:if prop.type == "Int"
Integer
:end-if
```

Used as: `{{ prop | javaType }}`

**Example — with-args modifier (`_modifiers_/wrap.teso`):**

```teso
---
input: value
type: String
params: prefix, suffix
---
{{ prefix }}{{ value }}{{ suffix }}
```

Used as: `{{ value | wrap("(", ")") }}`

**Implementation details:**
- `BlueprintModifierWithoutParams` / `BlueprintModifierWithParams` — the `Modifier` definition types (in `Symbols/Modifiers/BlueprintModifier.swift`).
- `BlueprintModifierLoader` — scans `_modifiers_/`, parses front matter, builds instances (in `Libs/BlueprintModifierLoader.swift`).
- `InputFileRepository.listFiles(inFolder:)` — added to the blueprint protocol with a default empty implementation; `LocalFileBlueprint` provides a real filesystem-backed implementation.
- Loading happens in `CodeGenerationSandbox.generateFilesFor(container:usingBlueprintsFrom:)`, after the blueprint is set and before the root folder + `main.ss` are rendered.

### `working_dir` Variable

Scripts control where output files land by setting `working_dir`. It is read by the sandbox's `setRelativePath()` to route generated files into the correct output subdirectory. Full variable reference in [`DSL/templatesoup.dsl.md`](DSL/templatesoup.dsl.md) §5.7.

---

## 10. Workspace, Context, and Sandbox

### `Workspace` (actor)

The public API facade. Entry point for:
- `config(_:)` — set configuration
- `newGenerationSandbox()` — create a `CodeGenerationSandbox` for code gen
- `newStringSandbox()` — create a sandbox for string-only rendering
- `render(string:data:)` — render a template string directly

### `LoadContext` (actor)

Holds state during the Load phase:
- `AppModel` — the growing in-memory model
- `OutputConfig` — pipeline configuration
- `variables` — config variables from `.tconfig` files

### `GenerationContext` (actor)

Extends `LoadContext` with rendering state:
- `symbols: TemplateSoupSymbols` — registered modifiers, operators, and statements
- `fileGenerator` — reference to the `CodeGenerationSandbox`
- `callStack: CallStack` — for error reporting
- `debugLog` — debug/trace utilities
- `pushSnapshot()` / `popSnapshot()` — scoped variable isolation via `SnapshotStack`

### `CodeGenerationSandbox` (actor)

The workhorse for code generation:

```
CodeGenerationSandbox
├── context: GenerationContext
├── templateSoup: TemplateSoup
├── base_generation_dir: OutputFolder    (config.output)
├── generation_dir: OutputFolder         (current relative subdirectory)
└── Methods:
    ├── generateFilesFor(container:usingBlueprintsFrom:)
    ├── generateFile(_:template:with:)
    ├── generateFileWithData(_:template:data:with:)
    ├── copyFile(_:with:) / copyFile(_:to:with:)
    ├── copyFolder(_:with:) / copyFolder(_:to:with:)
    ├── renderFolder(_:to:with:)
    └── fillPlaceholdersAndCopyFile(_:with:)
```

**Symbol loading** (via `loadSymbols([PreDefinedSymbols])`):
- `.typescript` → loads `TypescriptLib`
- `.mongodb_typescript` → additionally loads `MongoDB_TypescriptLib`
- `.java` → loads `JavaLib`
- `.noMocking` → skips `MockDataLib`
- Always loaded: `DefaultModifiersLibrary`, `DefaultOperatorsLibrary`, `StatementsLibrary`, `ModelLib`, `GenerationLib`, `GraphQLLib`

### `CodeGenerationEvents`

Optional event hooks on `PipelineConfig`:

| Hook | When called |
|---|---|
| `onBeforeRenderTemplateFile` | Before rendering a template file |
| `onBeforeRenderFile` | Before rendering any output file |
| `onBeforeParseTemplate` | Before parsing a template |
| `onBeforeExecuteTemplate` | Before executing a template |
| `onStartParseObject` | When the parser begins parsing a model object |

Return `false` from `onBeforeRenderFile` to skip generating that file.

---

## 11. DevTester Executable

**Path:** `DevTester/`

The `DevTester` target is the **development harness** — an executable that imports `ModelHike` and exercises the full pipeline. It is not the production CLI (which does not yet exist in this repo).

### `DevMain.swift`

```swift
@main struct Development {
    static func main() async {
        try await runCodebaseGeneration()   // currently active
        // try await runTemplateStr()       // for testing expression evaluation
    }
}
```

**`runCodebaseGeneration()`:**
- Uses `Pipelines.codegen`
- Config from `Environment.debug`
- Currently set to `config.containersToOutput = ["APIs"]`
- Commented-out hooks show how to enable per-file debug tracing

**`runTemplateStr()`:**
- Uses `Pipelines.empty`
- Tests raw template string rendering against a small data dictionary

**`inlineModel()`** (unused helper):
- Shows how to define models inline in Swift code (as an alternative to file-based loading)
- Demonstrates the `InlineModelLoader` / `InlineModel` / `InlineCommonTypes` API

### `Environment.swift`

Defines two `OutputConfig` presets:

| Config | basePath | localBlueprintsPath |
|---|---|---|
| `debug` | Points to a subfolder inside `_Playground/` (gitignored, local only) | Sibling `modelhike-blueprints` repo (must be cloned separately) |
| `production` | `~/Documents/modelhike` | `{basePath}/blueprints` |

> **Note:** Both paths are hardcoded relative to `~/Documents/` using `SystemFolder.documents.path`. The `debug` config points outside the repo root to a sibling `modelhike-blueprints` repository that must be checked out separately.

### Visual debugging (`--debug`)

When `--debug` is passed, `DevMain` switches to the visual debugging flow instead of the normal code-generation run. It captures a structured debug session, starts the local debug server, and can open the browser UI for inspection.

**Flags:** `--debug`, `--debug-port=<port>`, `--debug-dev` (serve HTML from Assets), `--no-open`

**Full reference:** [`Docs/debug/VISUALDEBUG.md`](Docs/debug/VISUALDEBUG.md) — runtime flow, architecture, integration inventory, event emission matrix, and troubleshooting.

---

## 12. Visual Debugging

ModelHike includes a browser-based visual debugger for pipeline runs. The current default experience is post-mortem inspection backed by a structured debug session, local debug server, and single-page browser UI.

Live stepping is scaffolded in the library but not enabled by default in `DevTester`. See [`Docs/debug/VISUALDEBUG.md`](Docs/debug/VISUALDEBUG.md) for the full architecture, data flow, implementation inventory, limitations, and troubleshooting guidance.

---

## 13. Tests

**Path:** `Tests/`

### `ExpressionParsing_Tests`

Tests the `RegularExpressionEvaluator` (boolean expression engine):

- `testComplexExpression1` through `testComplexExpression4` — various `and`/`or`/parenthesised combos
- `testInvalidExpressionError` — verifies `TemplateSoup_ParsingError.invalidExpression` is thrown

Uses `DynamicTestObj` (implements `DynamicMemberLookup + HasAttributes`) as test data.

### `TemplateSoup_String_Tests`

Tests end-to-end template string rendering:

- `testSimplePrint` — `{{ var1 }}`
- `testExpressionPrint` — `{{ (var1 and var2) and var2 }}`
- `testComplexTemplateWithMacroFunctions` — user-defined functions, set, nested renders, for loops, if/else
- `testSimpleNestedLoops` — deeply nested for + if + for

> **Note:** The test suite uses a synchronous `ws.render()` call which appears to be from an older synchronous API. The current production API is fully `async`. This may cause compilation issues; verify these tests compile and pass with current codebase.

---

## 14. Playground

**Path:** `_Playground/` — **gitignored; local development testing only. Contents are never committed and are not documented here.**

Used by `DevTester` (via `Environment.debug`) to run the full pipeline against real model files during development.

---

## 15. Current Project State & Known Gaps

### What Is Working

- ✅ Complete DSL parser — containers, modules, submodules, classes, DTOs, UIViews, properties, annotations, tags, attributes, API blocks, custom operations
- ✅ Full 6-phase pipeline (`Discover → Load → Hydrate → Transform → Render → Persist`)
- ✅ SoupyScript engine — all statement types, modifiers, operators, functions, loops, conditionals
- ✅ NestJS monorepo blueprint generation (TypeScript + MongoDB)
- ✅ Spring Boot blueprint infrastructure wired (Java symbols loaded) — needs an active blueprint
- ✅ GraphQL + gRPC API scaffolding support in the DSL and modifier libraries
- ✅ Annotation cascade system
- ✅ Type inference and hydration (entity/dto/cache/apiInput/embeddedType classification)
- ✅ Mock data generation library
- ✅ Expression evaluator (boolean/arithmetic/comparison)
- ✅ Scoped variable isolation (snapshot stack)
- ✅ Debug hooks (event system in `CodeGenerationEvents`)
- ✅ Visual debugger — post-mortem browser UI for pipeline runs (`swift run DevTester --debug`); see [Docs/debug/VISUALDEBUG.md](Docs/debug/VISUALDEBUG.md)

### What Is Hardcoded / Needs Refactoring

| Location | Hardcoded Value | Should Be |
|---|---|---|
| `GenerateCodePass.swift:24` | `let blueprint = "api-nestjs-monorepo"` | Driven by model config or CLI flag |
| `DevTester/Environment.swift:7` | Absolute path to a local test model folder inside `_Playground/` | Configurable |
| `DevTester/Environment.swift:9` | Absolute path to sibling `modelhike-blueprints` repo | Configurable, documented |
| `DevTester/DevMain.swift:31` | `config.containersToOutput = ["APIs"]` | Not hardcoded |

### DSL File Extension

The loader (`LocalFileModelLoader`) only reads files with extension `.modelhike` (via `ModelConstants.ModelFile_Extension`). `DSL/modelHike.dsl.md` uses `.dsl.md` — it is the DSL documentation, not a model file loaded by the engine.

### Gaps Between README and Implementation

The `README.md` describes a CLI tool with commands like `modelhike generate`, `modelhike validate`, `modelhike ai bootstrap`, etc. **None of these CLI commands exist in this repository.** The codebase is currently a Swift library + a developer executable. The CLI layer is not yet implemented.

Other README features not yet implemented:
- `modelhike validate` — validation engine (no standalone validator phase)
- `modelhike template freeze` — no freeze mechanism
- `modelhike adr new` — no ADR scaffolding tool
- `modelhike sbom` — no SBOM generation
- VS Code extension — not in this repo
- Web-based live sandbox — not in this repo

### External Dependency

The blueprints (template files that drive actual code generation) live in a **separate repository** `modelhike-blueprints`. This repo must be cloned alongside `modelhike` for `DevTester` to work. The path relationship is currently hardcoded in `Environment.swift`.

### Test Coverage

Only 2 test files exist:
- Expression parsing (5 tests)
- Template string rendering (4 tests)

No tests for:
- DSL model parsing
- Pipeline phases
- Hydration logic
- Blueprint loading
- File generation

---

## 16. Key Conventions & Patterns

### Naming Conventions

- Swift `actor` is used extensively for all mutable model objects and shared state (Swift 6 strict concurrency compliance).
- `givenname` — the original human-readable name from the DSL (may have spaces).
- `name` — the normalised variable-name-safe form (spaces replaced, camelCased).
- `pInfo: ParsedInfo` — threaded through virtually all methods for error reporting context.

### Code Patterns

- `ResultBuilder<T>` — used for `@PipelineBuilder`, `@CodeMemberBuilder`, `@InlineModelBuilder` DSLs.
- `@discardableResult` on append/generate methods — common pattern.
- `Sendable` conformance everywhere — required by Swift 6 strict concurrency. Actors, structs with `Sendable` properties.
- `DynamicMemberLookup + HasAttributes` — the pattern for objects that can be accessed by property name from within templates.

### File Naming

- Swift source files follow sub-folder organization, not flat.
- Blueprint template files use `.teso` extension (TemplateSoup → "template soup").
- Model-folder generation config: `main.tconfig` (`ModelConstants.ConfigFile_Extension = "tconfig"`) — loaded in Phase 2 by `LocalFileModelLoader.loadGenerationConfigIfAny()`. Key-value pairs only (not a script). Variables set here are available when `main.ss` runs.
- Blueprint SoupyScript entry point: `main.ss` (`TemplateConstants.ScriptExtension = "ss"`) — executed in Phase 5. Receives all variables populated by `main.tconfig` and the model.
- **ModelHike DSL model files use `.modelhike` extension** — this is the only extension `LocalFileModelLoader` reads.
- `common.modelhike` — special shared-types file loaded into `model.commonModel`.
- `main.tconfig` in model folder — generation config (key-value variables).
- `main.ss` in blueprint folder — SoupyScript entry-point script.

### `ModelConstants` Quick Reference

| Constant | Value | Meaning |
|---|---|---|
| `Member_Mandatory` | `*` | Required property |
| `Member_Optional` | `-` | Optional property |
| `Member_Optional2` | `_` | Optional (underscore; accepted as alias for `-`) |
| `Member_Conditional` | `*?` | Conditionally required |
| `Member_Calculated` | `=` | Calculated/derived property |
| `Member_Derived_For_Dto` | `.` | DTO field |
| `Member_Method` | `~` | Method inside a class |
| `Container_Member` | `+` | Module declaration inside container |
| `External_Import_File` | `+` | File import (same prefix as container member) |
| `AttachedSection` | `#` | API block or other attached section |
| `AttachedSubSection` | `##` | Sub-section entry (custom API operation) |
| `Annotation_Start` | `@` | Annotation prefix |
| `Annotation_Split` | `::` | Separator between annotation keyword and values |
| `NameUnderlineChar` | `=` | Class/DTO underline character |
| `UIViewUnderlineChar` | `~` | UIView underline character |
| `ModelFile_Extension` | `modelhike` | Model file extension scanned by loader |
| `ConfigFile_Extension` | `tconfig` | Generation config file extension |

### Concurrency Model

- Swift 6 (`swift-tools-version: 6.0`) with `async/await` throughout.
- All model objects (`C4Container`, `C4Component`, `DomainObject`, `Property`, `TemplateSoup`, `CodeGenerationSandbox`, etc.) are `actor`s.
- `Sendable` protocol conformance is enforced; `nonisolated(unsafe)` used sparingly (e.g., static regex patterns).
- Context snapshot stack (`pushSnapshot`/`popSnapshot`) provides scoped variable isolation without data races.

---

## 17. Glossary

| Term | Definition |
|---|---|
| **Blueprint** | A repository of `.teso` template files, static files, and a `main.ss` entry-point SoupyScript. Blueprints drive what code is generated. |
| **Container** | A deployable unit in the C4 model — maps to a microservice, web app, or database. Defined with `===...===` fences. |
| **Module / Component** | A C4 Component inside a Container; maps to a bounded context or functional grouping. |
| **DomainObject** | A persisted entity class with typed properties, mixins, and optional APIs. |
| **DTO** | Data Transfer Object — a flattened read-model that derives fields from parent types. |
| **UIView** | A UI component model; `dataType = .ui`. |
| **SoupyScript** | The custom scripting language used in blueprint `.ss` script files and `.teso` template files. In `.ss` files statements have no prefix; in `.teso` files script statements are prefixed with `:`. Full syntax in [`DSL/templatesoup.dsl.md`](DSL/templatesoup.dsl.md). |
| **TemplateSoup** | The rendering engine that evaluates `{{ expression }}` print-blocks and SoupyScript statements. Full syntax in [`DSL/templatesoup.dsl.md`](DSL/templatesoup.dsl.md). |
| **Modifier** | A function applied to a template value: `{{ value \| modifier }}`. |
| **Annotation** | A directive starting with `@` that automates tasks like CRUD scaffolding or index creation. |
| **Tag** | A free-form label (`#tag` or `#tag:value`) for searchable metadata. |
| **Attribute** | A key-value pair (`key=value`) attached to model elements; used for validation rules, routing, etc. |
| **Pipeline** | The 6-phase processing chain: Discover → Load → Hydrate → Transform → Render → Persist. |
| **Sandbox** | `CodeGenerationSandbox` — the actor that executes code generation for a single container against a blueprint. |
| **ModelSpace** | The root in-memory representation of all parsed models: `C4Container`s and `C4Component`s. |
| **PropertyKind** | Swift enum encoding the full DSL type system (int, string, bool, date, id, reference, codedValue, customType, etc.). |
| **pInfo** | `ParsedInfo` — carries line number, file identifier, parser reference, and context; passed through all parsing/evaluation methods for error location reporting. |
| **tconfig** | `main.tconfig` — a key-value config file placed in the model folder (alongside `.modelhike` files). Loaded in Phase 2 before `main.ss` is invoked. Sets generation variables (e.g. port numbers, prefixes) available throughout Phase 5 rendering. Not a script. |
| **.ss** | SoupyScript file extension (`TemplateConstants.ScriptExtension = "ss"`). `main.ss` is the blueprint entry point. |
| **teso** | A TemplateSoup template file (`.teso` extension) rendered against the generation context. |
| **common.modelhike** | Special shared-types file in the model folder. Loaded into `model.commonModel`; types here are available as mixins/parents across all containers. |
| **MethodObject** | A method member inside a class (prefix `~`). Has `parameters`, `returnType`, and `body`. |
| **backend attribute** | `(backend)` on a property or field — marks it as server-side only, excluded from client schemas by blueprints that honour this convention. |
| **MappingAnnotation** | The `@list-api` annotation value type: a list of `(key, value)` pairs expressed as `prop -> prop.sub; prop2 -> prop2`. |
| **Visual Debugger** | Post-mortem browser-based inspection of pipeline runs. Run `swift run DevTester --debug`; captures events, source, variables, rendered output. Full docs in [Docs/debug/VISUALDEBUG.md](Docs/debug/VISUALDEBUG.md). |
