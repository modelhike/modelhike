# AI-Native Debugging Commands — Implementation Status

> Last updated: 2026-04-07 (gaps fixed)
> Build status: **clean** (`swift build` passes, zero errors, zero warnings)

---

## Overview

This effort adds 8 new CLI/MCP commands + 1 rename + 1 enhancement to make the ModelHike Smart CLI fully AI-native. The work was designed around 10 real AI agent flows and the gaps each one hits.

The full design rationale is in the Cursor plan file: `.cursor/plans/ai-native_debug_commands_0662e044.plan.md`

---

## Status Matrix

| # | Item | Type | Status | Notes |
|---|------|------|--------|-------|
| 1 | `dsl-schema-in-markdown` | Rename | **DONE** | CLI + MCP tool + router renamed from `schema-in-markdown` |
| 2 | `what-depends-on` enhancement | Enhancement | **DONE** | DependencyWalker scans snapshot (property types, method returns, annotations, tags, @Target refs) + live AppModel (appliedConstraints, appliedDefaultExpression, method param types, module expressions, named constraints). `BreakingChange` type + `--change rename\|remove` flag. |
| 3 | `list-types` | New command | **DONE** | Engine + Result + CLI + MCP + Formatter |
| 4 | `fix` | New command | **DONE** | Engine + Result + CLI + MCP + Formatter. Real line-level text manipulation: W301 types replaced via `didYouMean` or single-option `availableOptions` suggestions. |
| 5 | `preflight` | New command | **DONE** | Engine + Result + CLI + MCP + Formatter. Checks syntax, W301-W306, blueprint availability. Real per-container `#blueprint(...)` tag parsing from model text with validation against available blueprints. |
| 6 | `trace` | New command | **TODO** | Not started |
| 7 | `describe-blueprint` | New command | **TODO** | Not started |
| 8 | `dry-run` | New command | **DONE** | Former non-persisting `generate` behavior is now exposed explicitly as `dry-run`. New `generate` persists through the upstream Persist phase. |
| 9 | `graph` | New command | **TODO** | Not started |
| 10 | `diff` | New command | **TODO** | Not started |
| — | `impact` (original) | Cancelled | **N/A** | Folded into `what-depends-on` enhancement |

---

## What Was Built (files touched/created)

### New files

| File | Purpose |
|------|---------|
| `Sources/ModelHikeKit/Results/TypeListResult.swift` | `TypeInfo` + `TypeListResult` |
| `Sources/ModelHikeKit/Results/FixResult.swift` | `FixAction` + `FixResult` |
| `Sources/ModelHikeKit/Results/PreflightResult.swift` | `PreflightCheck` + `PreflightResult` |
| `Sources/CLI/Commands/ListTypesCommand.swift` | `modelhike list-types` |
| `Sources/CLI/Commands/FixCommand.swift` | `modelhike fix` |
| `Sources/CLI/Commands/PreflightCommand.swift` | `modelhike preflight` |
| `Sources/CLI/Commands/DryRunCommand.swift` | `modelhike dry-run` |

### Modified files

| File | What changed |
|------|-------------|
| `Sources/ModelHikeKit/ModelHikeEngine.swift` | Added `listTypes()`, `fix()`, `preflight()` engine methods. Enhanced `whatDependsOn()` with `changeKind`/`newName` params. |
| `Sources/ModelHikeKit/DependencyWalker.swift` | Full rewrite. Now scans property types, method return types, annotations, tags, @Target refs. Added `computeBreakingChanges()`. `references()` returns `[Reference]` for backward compat with `inspect`. |
| `Sources/ModelHikeKit/Results/DependencyResult.swift` | `Dependent` struct replaced (new fields: `location`, `referenceKind`, `rawValue`). Added `BreakingChange`. `DependencyResult` gains `breakingChanges` field. |
| `Sources/CLI/ModelHikeCLI.swift` | Registered `ListTypesCommand`, `FixCommand`, `PreflightCommand`, `DryRunCommand` |
| `Sources/CLI/Commands/WhatDependsOnCommand.swift` | Added `--change` and `--new-name` flags |
| `Sources/CLI/Commands/SchemaInMarkdownCommand.swift` | Renamed command to `dsl-schema-in-markdown` |
| `Sources/CLI/Formatting/OutputFormatter.swift` | Added formatters for `TypeListResult`, `FixResult`, `PreflightResult`. Updated `DependencyResult` formatter for new fields. |
| `Sources/MCP/ToolDefinitions.swift` | Added `modelhike/list-types`, `modelhike/fix`, `modelhike/preflight`. Renamed `modelhike/schema-in-markdown` → `modelhike/dsl-schema-in-markdown`. Enhanced `modelhike/what-depends-on` with `change`/`newName` inputs. |
| `Sources/MCP/ToolRouter.swift` | Added router cases for `list-types`, `fix`, `preflight`. Updated `what-depends-on` to pass `change`/`newName`. Renamed schema case. Added `optionalString()` helper. |

---

## Known Gaps — All Resolved

All three known gaps from the initial implementation have been fixed:

### `fix` command — FIXED: real line-level text manipulation

The `fix` engine method now:
- Uses `collectFixes()` to analyze each diagnostic and build `PendingFix` objects with line-targeted transform closures
- Uses `applyFixes()` to apply transforms in reverse line order (so line numbers stay stable)
- For W301: extracts the unresolved type name from `SourceRef.lineContent`, finds the best replacement from `didYouMean` suggestions (preferred) or single-option `availableOptions`, and replaces the type name on the exact line
- Uses `extractUnresolvedTypeName()` to parse DSL property syntax (`* field: Type`, `- field: Type[1..*]`, `* field: Type@Target`, etc.)
- Correctly handles multiple W301s on different lines in the same model

### `preflight` command — FIXED: real per-container blueprint tag check

The `preflight` engine method now:
- Reads the raw model text and parses container blocks using `parseBlueprintTags()` (line-oriented DSL parsing: `===` start fence → container name → `====` end fence → `#blueprint(name)` tag)
- Cross-references parsed tags with container names from `explain()` result
- Reports specific untagged containers by name
- Validates tagged blueprint names against available blueprints (catches invalid names)
- Handles `--blueprint` override: validates the override name exists in available blueprints
- Adds a `modules_resolved` check (W303) alongside existing W301-W306 checks

### `what-depends-on` — FIXED: live AppModel scanning

The `whatDependsOn` engine method now:
- Runs the pipeline directly (Load + Hydrate + Annotations) instead of just calling `explain()`
- Accesses the live `AppModel` via `pipeline.ws.context.model`
- `DependencyWalker.liveModelDependents()` walks the actor graph for:
  - `Property.appliedConstraints` — named constraints referencing the entity
  - `Property.appliedDefaultExpression` — default expressions (`@ExpressionName`)
  - `MethodObject.parameters` — method parameter types referencing the entity
  - `C4Component.expressions` — module-level expression types
  - `C4Component.namedConstraints` — module-level named constraints
- `DependencyWalker.mergeDependents()` deduplicates snapshot-based and live-model dependents

---

## Remaining Commands (Tier 2 + 3)

### `trace` — Opaque failure debugging

**Priority: Tier 2 (high value)**

Exposes the full `DebugSession` timeline when a pipeline fails. Key implementation steps:

1. **Result type**: `TraceResult` with `phases: [PhaseRecord]`, `events: [TraceEvent]`, `errors: [ErrorDetail]`, `filesAttempted: [FileAttempt]`
2. **Engine method**: Run the same pipeline as `generate`/`validate`, but instead of just extracting diagnostics from `DebugSession`, map the full session:
   - `session.phases` → phase name, status, duration
   - `session.events` → filter to actionable types (skip `variableSet`, `expressionEvaluated`; keep `phaseStarted/Completed/Failed`, `fileGenerated/Skipped/Failed`, `error`, `diagnostic`, `fatalError`, `consoleLog`)
   - `session.errors` → message, category, source location, call stack (from `ErrorRecord`)
   - `session.files` → path, template name, status
3. **Key upstream types**: `DebugSession`, `PhaseRecord`, `DebugEventEnvelope`, `DebugEvent` (in `.build/checkouts/modelhike/Sources/Debug/`)
4. **Gotcha**: The `StdoutCapture.run` async closure has a Swift 6 quirk where `.filter {}` / `.contains {}` closures are treated as async. Use `for` loops instead.

### `describe-blueprint` — Blueprint introspection

**Priority: Tier 2**

1. **Result type**: `BlueprintDescription` with `name`, `templates: [String]`, `entryScript: String?`, `staticFiles: [String]`
2. **Engine method**: Use `BlueprintAggregator` to resolve the blueprint, then enumerate its contents
3. **Key upstream types**: `BlueprintAggregator`, `LocalFileBlueprint`, `OfficialBlueprintFinder` — the `Blueprint` protocol exposes file listings
4. **Challenge**: Official blueprints are bundled as resources in the `modelhike-blueprints` package. Need to check if `OfficialBlueprint` exposes template/file enumeration or if only `main.ss` + render is accessible.

### `graph` — Relationship graph

**Priority: Tier 3**

1. **Result type**: `GraphResult` with `nodes: [GraphNode]`, `edges: [GraphEdge]`, `clusters: [Cluster]`, `orphans: [String]`, `cycles: [[String]]`
2. **Engine method**: After Load + Hydrate, walk all entities and properties to build adjacency list. Run DFS for cycle detection.
3. **Human format**: Output Mermaid-compatible diagram syntax so the AI can render it for the developer.
4. **Reuses**: Much of `DependencyWalker`'s scanning logic, but applied to ALL entities at once instead of one target.

### `diff` — Semantic model comparison

**Priority: Tier 3**

1. **Result type**: `DiffResult` with per-entity change records (added/removed/modified) and a summary
2. **Engine method**: Run Load + Hydrate on both models, produce two `ExplanationResult`s, then walk both trees comparing by normalized entity name
3. **Input pattern**: Needs dual-input — CLI: `--before <path> --after <path>`, MCP: `{ "before": "...", "after": "..." }`
4. **Challenge**: `ModelInput` currently supports single input. Need a new engine method signature that takes two inputs.

---

## Implementation Pattern (for future commands)

Every new command follows the same 7-step pattern:

1. **Result type** in `Sources/ModelHikeKit/Results/` — `Codable & Sendable & Equatable`
2. **Engine method** in `Sources/ModelHikeKit/ModelHikeEngine.swift` — wrap in `StdoutCapture.run { ... }`
3. **CLI subcommand** in `Sources/CLI/Commands/` — register in `ModelHikeCLI.swift`
4. **MCP tool definition** in `Sources/MCP/ToolDefinitions.swift`
5. **MCP router case** in `Sources/MCP/ToolRouter.swift`
6. **Formatter** in `Sources/CLI/Formatting/OutputFormatter.swift` — both `.json` and `.human`
7. **Update docs**: `AGENTS.md`, `docs/cli-reference.md`, `docs/mcp-reference.md`

### Swift 6 async gotcha

Inside `StdoutCapture.run { ... }` closures, the Swift 6 compiler treats `.filter {}`, `.contains {}`, `.first(where:)` etc. as async calls. **Use explicit `for` loops instead of higher-order functions** when operating on arrays inside these closures. This is a known quirk of the strict concurrency model.

---

## Docs / Tests Status

The public docs were updated to reflect the implemented commands:

- [x] `AGENTS.md` — command table, result types, CLI command docs, MCP tool schemas, file structure
- [x] `docs/cli-reference.md` — added `list-types`, `fix`, `preflight`; updated `what-depends-on`; renamed `dsl-schema-in-markdown`
- [x] `docs/mcp-reference.md` — added `modelhike/list-types`, `modelhike/fix`, `modelhike/preflight`; updated `what-depends-on`; renamed `modelhike/dsl-schema-in-markdown`
- [ ] `DevTester_MCP/Sources/SmokeRunner.swift` — add smoke tests for new MCP tools
- [ ] `Tests/ModelHikeKitTests/` — add unit tests for new engine methods

---

## Quick Resume Checklist

To continue this work in a future session:

1. Read this file for context
2. Read the plan: `.cursor/plans/ai-native_debug_commands_0662e044.plan.md`
3. Run `swift build` to verify the codebase is clean
4. Pick the next TODO from the status matrix above
5. Follow the 7-step implementation pattern
6. Watch out for the Swift 6 async gotcha with closures
