# MCP Reference

`modelhike-mcp` exposes the smart CLI surface as MCP tools over stdio.

## Server Characteristics

- transport: stdio
- capability: tools
- server name: `modelhike`
- server version: `1.0.0`

## Cursor Configuration

```json
{
  "mcpServers": {
    "modelhike": {
      "command": "/absolute/path/to/modelhike-smart-cli/.build/debug/modelhike-mcp",
      "transportType": "stdio"
    }
  }
}
```

Bundled official blueprints (from the `modelhike-blueprints` package) are available by default. Supply `--blueprints <path>` or `MODELHIKE_BLUEPRINTS` only when you want to layer in a local blueprint directory.

## Tool Catalog

### `modelhike/validate`

#### Input

```json
{
  "content": "string"
}
```

#### Behavior

- parses inline `.modelhike` content
- hydrates the model
- returns diagnostics suitable for iterative correction

#### Output

Structured content is a `ValidationResult`.

### `modelhike/generate`

#### Input

```json
{
  "content": "string",
  "blueprint": "string",
  "outputPath": "string"
}
```

#### Behavior

- loads and validates inline content
- runs generation against the named blueprint
- persists output to `outputPath` when provided, otherwise to `<cwd>/modelhike-output`
- returns generated files, a file tree, and the resolved output directory

#### Output

Structured content is a `GenerationResult`.

### `modelhike/dry-run`

#### Input

```json
{
  "content": "string",
  "blueprint": "string"
}
```

#### Behavior

- loads and validates inline content
- runs render against the named blueprint without persisting output
- returns generated files and a file tree preview

#### Output

Structured content is a `GenerationResult`.

### `modelhike/inline-generate`

#### Input

```json
{
  "content": "string",
  "inlineBlueprint": {
    "name": "string",
    "scripts": {
      "main": "string"
    },
    "templates": {},
    "folders": {},
    "modifiers": {}
  },
  "outputPath": "string"
}
```

#### Behavior

- loads and validates inline `.modelhike` content
- builds an `InlineBlueprint` from the provided JSON object
- runs upstream `InlineGenerationHarness`
- persists output to `outputPath` when provided; otherwise returns a preview without persisting

#### Output

Structured content is a `GenerationResult`.

### `modelhike/explain`

#### Input

```json
{
  "content": "string"
}
```

#### Behavior

- loads and hydrates inline content
- returns containers, modules, entities, properties, methods, and inferred APIs

#### Output

Structured content is an `ExplanationResult`.

### `modelhike/inspect`

#### Input

```json
{
  "content": "string",
  "entity": "string"
}
```

#### Output

Structured content is an `InspectionResult`.

### `modelhike/what-depends-on`

#### Input

```json
{
  "content": "string",
  "entity": "string",
  "change": "rename|remove",
  "newName": "string"
}
```

#### Behavior

- returns reverse dependencies across property types, method return types, annotations, tags, and `@Target` references
- optionally returns `breakingChanges` guidance for rename/remove planning

#### Output

Structured content is a `DependencyResult`.

### `modelhike/list-types`

#### Input

```json
{
  "content": "string"
}
```

#### Behavior

- loads and hydrates inline content
- returns all declared model types grouped by container/module in structured form

#### Output

Structured content is a `TypeListResult`.

### `modelhike/fix`

#### Input

```json
{
  "content": "string",
  "codes": "W301,W307"
}
```

#### Behavior

- validates inline content
- attempts supported auto-fixes
- returns corrected model text plus applied/remaining fix records

#### Output

Structured content is a `FixResult`.

### `modelhike/preflight`

#### Input

```json
{
  "content": "string",
  "blueprint": "string"
}
```

#### Behavior

- validates and hydrates inline content
- checks generation readiness before `generate`
- reports actionable checklist items and a `ready` boolean

#### Output

Structured content is a `PreflightResult`.

### `modelhike/list-blueprints`

#### Input

```json
{}
```

#### Output

Structured content is a `BlueprintListResult`.

### `modelhike/dsl-schema-in-markdown`

#### Input

```json
{}
```

#### Behavior

- loads the three canonical DSL markdown files bundled in the `modelhike` core package (`modelHike.dsl.md`, `codelogic.dsl.md`, `templatesoup.dsl.md`)
- returns their full text as three JSON string fields (no model input required)

#### Output

Structured content is a `DSLMarkdownSchemaResult`:

```json
{
  "modelHikeDSL": "# ModelHike DSL …",
  "codeLogicDSL": "# Code Logic …",
  "templateSoupDSL": "# TemplateSoup …"
}
```

If resources cannot be loaded, the tool returns `isError: true`.

## Typical AI Workflow

### 0. (Optional) Load DSL spec

Call `modelhike/dsl-schema-in-markdown` with empty arguments so the agent has the full grammar in structured form before drafting.

### 1. Draft a model from intent

User:

```text
I need a microservice for handling customer subscriptions with Stripe integration.
```

Agent writes draft `.modelhike` content.

### 2. Validate in a loop

Tool call:

```json
{
  "name": "modelhike/validate",
  "arguments": {
    "content": "..."
  }
}
```

Example outcome:

```json
{
  "valid": false,
  "diagnostics": [
    {
      "severity": "warning",
      "code": "W301",
      "message": "Type 'StripeEvent' referenced by property 'event' in 'WebhookHandler' not found."
    }
  ]
}
```

Agent fixes the model and re-validates.

### 3. Explain before generating

Tool call:

```json
{
  "name": "modelhike/explain",
  "arguments": {
    "content": "..."
  }
}
```

Agent presents the architecture summary to the developer.

### 4. Generate deterministic output

Tool call:

```json
{
  "name": "modelhike/generate",
  "arguments": {
    "content": "...",
    "blueprint": "api-springboot-monorepo",
    "outputPath": "./generated"
  }
}
```

Result:

- generated file manifest
- file tree
- resolved output directory
- generation diagnostics

## Structured Content

The MCP server returns:

- a small text content payload (`"OK"`) for human visibility
- structured JSON content for machine use

Clients should prefer `structuredContent`. Every result type includes a `diagnostics` array — agents should always inspect it, not just for `validate`.

## Error Behavior

- invalid input or unresolved environment issues surface as `isError: true`
- semantic validation issues are part of normal structured output
- generation problems inside templates/blueprints are returned as diagnostics in the result

## Stability Contract

Tool names are treated as public API:

- `modelhike/validate`
- `modelhike/generate`
- `modelhike/dry-run`
- `modelhike/inline-generate`
- `modelhike/explain`
- `modelhike/inspect`
- `modelhike/what-depends-on`
- `modelhike/list-types`
- `modelhike/fix`
- `modelhike/preflight`
- `modelhike/list-blueprints`
- `modelhike/dsl-schema-in-markdown`

If any tool name, input shape, or result shape changes, update:

- `AGENTS.md`
- this document
- CLI reference if the same behavior is also exposed by `modelhike`
