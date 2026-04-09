# ModelHike Smart CLI

`modelhike-smart-cli` is the interface layer for ModelHike.

- `modelhike` is a non-interactive CLI designed for both humans and AI agents.
- `modelhike-mcp` exposes the same deterministic operations as MCP tools over stdio.
- `ModelHikeKit` is the shared Swift library both executables call into.

## Positioning

ModelHike is not a code generator that uses AI. It is a deterministic compilation target for AI.

- AI turns intent into `.modelhike` content.
- ModelHike validates that source of truth and generates deterministic output from it.
- This package makes that loop accessible from a CLI and from MCP.

## What “Smart CLI” Means

- No prompts, menus, or interactive confirmations.
- Inputs come from flags, paths, environment variables, or stdin.
- Outputs are structured and predictable.
- Validation returns machine-usable diagnostics with stable codes.
- Generation returns a file manifest and tree, not just text logs.

## Package Layout

```text
modelhike-smart-cli/
├── Package.swift
├── AGENTS.md
├── Sources/
│   ├── ModelHikeKit/
│   ├── CLI/
│   └── MCP/
├── DevTester_MCP/
├── Tests/
│   └── ModelHikeKitTests/
└── docs/
```

## Requirements

- macOS
- Swift 6 toolchain

The package manifest uses Swift tools `6.2`. The `modelhike` and `modelhike-blueprints` upstream packages are resolved automatically as remote dependencies via Swift Package Manager.

## Installation

Build the package:

```bash
swift build
```

Run the CLI:

```bash
swift run modelhike --help
```

Run the MCP server:

```bash
swift run modelhike-mcp
```

Bundled official blueprints (from the `modelhike-blueprints` package) are available by default. Pass `--blueprints <path>` or set `MODELHIKE_BLUEPRINTS` only when you want to layer in a local blueprint directory.

## Quick Start

Validate inline model content:

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* owner: CustomerProfile\n' \
  | swift run modelhike validate --input -
```

Explain a model:

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* name: String\n' \
  | swift run modelhike explain --input -
```

List blueprints:

```bash
swift run modelhike list-blueprints \
  --format human
```

## Documents

- `docs/cli-reference.md` for command-by-command CLI usage.
- `docs/mcp-reference.md` for MCP tool schemas and examples.
- `docs/smart-cli-philosophy.md` for the AI-agent operating model.
- `docs/architecture.md` for internals and implementation details.
