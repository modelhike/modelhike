# CLI Reference

The `modelhike` executable is intentionally non-interactive.

- Default output format: human
- Alternate output format: `--format human`
- Default input when `--input` is omitted: current directory
- Stdin input: `--input -`
- `inline-generate` is the exception: it requires `--input`, does not read stdin, and accepts either a file path or an inline string.

## Common Flags

- `--input <path>`: model file path, model directory path, or `-` for stdin (all commands except `list-blueprints`, `dsl-schema-in-markdown`, and `inline-generate`)
- `--format json|human`: output format (all commands)
- `--blueprints <path>`: optional local blueprint root layered on top of bundled official blueprints (`validate`, `generate`, `dry-run`, `list-blueprints`). Alternatively, set the `MODELHIKE_BLUEPRINTS` environment variable.

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success with no diagnostics |
| `1` | Success with warnings |
| `2` | Validation or semantic errors |
| `3` | Parse / input resolution failure |
| `4` | Generation failure |

## validate

```bash
modelhike validate [--input <path-or-stdin>] [--format json|human] [--blueprints <path>]
```

Returns structured diagnostics. The `valid` field is `false` if there are any diagnostics at all (warnings or errors), not just errors. This makes it safe for AI-agent loops: validate until `valid: true`.

### Example

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* owner: CustomerProfile\n' \
  | swift run modelhike validate --input -
```

### JSON shape

```json
{
  "valid": false,
  "diagnostics": [
    {
      "severity": "warning",
      "code": "W301",
      "message": "Type 'CustomerProfile' referenced by property 'owner' in 'Subscription' not found.",
      "source": {
        "fileIdentifier": "",
        "lineNo": 0,
        "lineContent": "owner",
        "level": 0
      },
      "suggestions": []
    }
  ],
  "summary": {
    "total": 1,
    "errors": 0,
    "warnings": 1,
    "infos": 0,
    "hints": 0,
    "highestSeverity": "warning"
  }
}
```

## generate

```bash
modelhike generate [--input <path-or-stdin>] [--blueprint <name>] [--container <name> ...] [--system-view <name> ...] [--output <dir>] [--format json|human] [--blueprints <path>]
```

Runs full generation and persists the output directory using either:

- the model's own `#blueprint(name)` tags, or
- an optional `--blueprint` override

- With `--output`, files are written there.
- Without `--output`, files are written to `<basePath>/modelhike-output`.
- The result still includes the generated file manifest and tree for machine use.

### Targeting rules

- If `--blueprint` is provided, you must also provide at least one target selector: `--container` or `--system-view`.
- Only one target kind may be used per invocation.
- `--container` selects containers by name (including composite / container-group containers, per upstream resolution).
- `--system-view` is not yet supported for generation in `modelhike-smart-cli` (upstream system rendering is not wired through here).

### Example

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* name: String\n' \
  | swift run modelhike generate \
      --input - \
      --blueprint api-nestjs-monorepo \
      --container APIs \
      --output ./generated
```

### Notes

- Real blueprints may require additional model/config variables.
- If blueprint templates reference missing variables, generation returns diagnostics and exits non-zero.

## dry-run

```bash
modelhike dry-run [--input <path-or-stdin>] [--blueprint <name>] [--container <name> ...] [--system-view <name> ...] [--format json|human] [--blueprints <path>]
```

Runs the same load, hydrate, validate, and render flow as `generate`, but does not persist any files. Use it to preview the file tree and generated file manifest before writing to disk.

### Example

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* name: String\n' \
  | swift run modelhike dry-run \
      --input - \
      --blueprint api-nestjs-monorepo \
      --container APIs
```

## inline-generate

```bash
modelhike inline-generate --input <model-file-or-inline-string> --inline-blueprint <blueprint-json-file-or-inline-json-string> [--container <name> ...] [--output <dir>] [--format json|human]
```

Runs the upstream `InlineGenerationHarness` using:

- a single model provided as either a file path or an inline `.modelhike` string
- an inline blueprint provided as either a JSON file path or a raw JSON string

Unlike the other commands, `inline-generate` never reads stdin and does not default `--input` to the current directory.

- Without `--output`, it returns a preview (`persisted: false`)
- With `--output`, it writes the generated files there and returns the same file manifest/tree

### Inline blueprint JSON shape

```json
{
  "name": "inline-preview",
  "scripts": {
    "main": " "
  },
  "folders": {
    "_root_": {
      "Readme": "Hello from blueprint"
    }
  }
}
```

### Example with inline strings

```bash
swift run modelhike inline-generate \
  --input $'===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n' \
  --inline-blueprint '{"name":"inline-preview","scripts":{"main":" "},"folders":{"_root_":{"Readme":"Hello from blueprint"}}}' \
  --container APIs
```

## explain

```bash
modelhike explain [--input <path-or-stdin>] [--format json|human]
```

Returns a structural summary of the model:

- containers
- modules
- entities
- properties
- methods
- generated API surfaces inferred by ModelHike hydration

This is the CLI equivalent of “show me what this model means before generating code.”

## inspect

```bash
modelhike inspect <entity> [--input <path-or-stdin>] [--format json|human]
```

Returns:

- the selected entity
- its properties and methods
- annotations and tags
- references pointing at it
- generated artifacts inferred from attached APIs

## what-depends-on

```bash
modelhike what-depends-on <entity> [--input <path-or-stdin>] [--change rename|remove] [--new-name <name>] [--format json|human]
```

Returns reverse dependencies by walking:

- property types
- method return types
- annotations
- tags
- `@Target` references

With `--change`, also returns `breakingChanges` guidance for rename/remove workflows.

## list-types

```bash
modelhike list-types [--input <path-or-stdin>] [--format json|human]
```

Lists all declared model types, grouped by container and module. Useful for resolving `W301` unresolved-type diagnostics without forcing the agent to parse `explain` output.

## fix

```bash
modelhike fix [--input <path-or-stdin>] [--codes <W301,W307,...>] [--format json|human]
```

Attempts auto-repair for supported diagnostics and returns:

- whether fixes were applied
- the corrected model text
- an audit trail of applied fixes
- diagnostics that could not be fixed automatically

## preflight

```bash
modelhike preflight [--input <path-or-stdin>] [--blueprint <name>] [--format json|human]
```

Runs a generation-readiness checklist before calling `generate`. It combines validation diagnostics with blueprint availability checks and returns a `ready` boolean plus actionable fix hints.

## list-blueprints

```bash
modelhike list-blueprints [--blueprints <path>] [--format json|human]
```

Lists bundled official blueprints and any optional local overrides supplied via `--blueprints`.

### Example

```bash
swift run modelhike list-blueprints --format human
```

## dsl-schema-in-markdown

```bash
modelhike dsl-schema-in-markdown [--format json|human]
```

Prints the three bundled canonical DSL specification files from the `modelhike` dependency: `modelHike.dsl.md`, `codelogic.dsl.md`, and `templatesoup.dsl.md`. Human mode concatenates them with headings; JSON mode returns a single object with three string fields (`modelHikeDSL`, `codeLogicDSL`, `templateSoupDSL`). Does not use `--input` or `--blueprints`. Exit code `4` if the bundled resources cannot be read.

### Example

```bash
swift run modelhike dsl-schema-in-markdown --format json | head -c 500
```

## Input Resolution Rules

### `--input -`

Reads all stdin as a UTF-8 string and treats it as a single inline `.modelhike` source.

### `--input /path/to/file.modelhike`

Loads that file as the main model, plus adjacent optional support files if present:

- `common.modelhike`
- `main.tconfig`

### `--input /path/to/folder`

Loads all `*.modelhike` files in the folder, plus optional:

- `common.modelhike`
- `main.tconfig`

## Human Output

`--format human` is optimized for terminals, not parsers.

Use `--format json` when:

- another program consumes the output
- an AI agent needs structured responses
- you want stable machine-readable behavior across versions
