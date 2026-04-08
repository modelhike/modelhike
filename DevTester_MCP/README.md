# DevTester_MCP

Swift 6.2 executable target in the main package for smoke-testing `modelhike-mcp` with the official Swift MCP client.

## What It Does

- Launches `modelhike-mcp` as a child process
- Connects with `MCP.Client`
- Verifies `initialize` and `tools/list`
- Calls the ModelHike MCP tools end-to-end
- Asserts on structured content like diagnostics, entity counts, blueprint names, and generated file paths

## Default Behavior

From the repo root:

```bash
swift run DevTester_MCP
```

By default it launches the local MCP server target with:

```bash
swift run --package-path /path/to/ modelhike-mcp
```

and runs a full smoke pass using built-in valid/invalid `.modelhike` fixtures.

## Useful Overrides

Run a subset of tools:

```bash
swift run DevTester_MCP --tool modelhike/validate --tool modelhike/generate
```

Use a prebuilt server binary:

```bash
swift run DevTester_MCP --server-binary .build/debug/modelhike-mcp
```

Use custom models and expectations:

```bash
swift run DevTester_MCP \
  --valid-model-file /tmp/valid.modelhike \
  --invalid-model-file /tmp/invalid.modelhike \
  --entity Payment \
  --expect-diagnostic-code W301 \
  --expect-reference Invoice \
  --expect-dependent Invoice \
  --expect-generated-suffix /package.json
```

Emit JSON for automation:

```bash
swift run DevTester_MCP --output json
```
