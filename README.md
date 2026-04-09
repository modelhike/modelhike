# ModelHike - Declarative Apps

> **Declarative Apps are here.** Give your AI agent deterministic code generation — through Agent Skills and MCP tools backed by the [ModelHike](https://github.com/modelhike/modelhike) architecture compiler.

---

## 🚀 The Declarative App Paradigm

We used to write code. Then we asked AI to write code for us. But code is the wrong abstraction for AI generation. 

When you ask an AI to generate a backend, you get a massive wall of code. When you ask it again, you get different code. There's no stable source of truth, no diff, no way for the AI to reason about what changed.

**ModelHike introduces the Declarative App.**

Instead of struggling with generated spaghetti code, you and your AI build a declarative model of your application. 

> The AI writes the **model**. ModelHike writes the **code**.

The `.modelhike` file is the source of truth — a markdown-inspired DSL that sits between natural-language intent and generated production code. It is stable, diffable, and reviewable. Any AI can write to it. ModelHike guarantees the always-deterministic code generation output.

```
===
Billing APIs   #blueprint(api-nestjs-monorepo)
====
+ Billing

=== Billing ===

Subscription
============
** _id: String
*  plan: Plan
*  owner: Customer
*  startDate: Date
-  cancelledAt: Date
~  cancel(): void
~  renew(months): Subscription

Plan
====
** _id: String
*  name: String
*  price: Decimal
*  interval: String
```

Containers, modules, entities, properties, methods, references, blueprint tags — all expressed in a lightweight text format that an AI can draft in one shot and a human can read at a glance.

---

## The AI Loop

```
"I need a subscriptions microservice with Stripe"
               ↓
    AI drafts a .modelhike model
               ↓
  modelhike/validate        →  W301: type 'Plan' not found
               ↓ (AI fixes and retries)
  modelhike/validate        →  ✓ no issues
               ↓
  modelhike/explain         →  "Here's what I'm about to generate..."
               ↓ (developer approves)
  modelhike/generate        →  deterministic file tree
```

Every tool call returns structured JSON. Every diagnostic carries a stable code, a source location, and machine-actionable suggestions. The agent drives the entire loop through MCP tool calls — no shell, no parsing, no human in the loop until the final approval.

This package gives AI agents structured tool access to validate, explain, inspect, and generate code from `.modelhike` model files. The primary interface is an **MCP server** (`modelhike-mcp`) that any MCP-aware agent — Cursor, Windsurf, Claude Code, or your own tooling — can call over stdio. A direct **Smart CLI** (`modelhike`) exposes the same engine for shell scripting, CI pipelines, and debugging.

---

## Getting Started

**Requirements:** macOS, Swift 6 toolchain. Upstream packages (`modelhike-lib`, `modelhike-blueprints`) are resolved automatically via SPM.

```bash
swift build
```

Add the MCP server to your agent config (Cursor example):

```json
{
  "mcpServers": {
    "modelhike": {
      "command": "/path/to/.build/debug/modelhike-mcp",
      "transportType": "stdio"
    }
  }
}
```

Your agent now has access to every ModelHike tool. To verify the engine directly from a terminal instead, see the [CLI](#cli) section below.

---

## MCP Tools

Every tool returns structured JSON content with a `diagnostics` array. The MCP server runs over stdio — no HTTP, no configuration beyond the launch command.

| Tool | What it does |
|---|---|
| `modelhike/validate` | Parse and validate a model. Returns structured diagnostics with codes like `W301`. |
| `modelhike/generate` | Compile the model and persist generated output to disk. Returns the file manifest and output directory. |
| `modelhike/dry-run` | Preview generated files and the output tree without writing anything. |
| `modelhike/inline-generate` | Generate from inline model content and an inline blueprint JSON object. |
| `modelhike/explain` | Summarize what a model means — containers, entities, APIs, relationships. |
| `modelhike/inspect` | Drill into one entity: properties, references, generated artifacts. |
| `modelhike/what-depends-on` | Show reverse dependencies across model references, with optional rename/remove impact analysis. |
| `modelhike/list-types` | List all declared model types so agents can resolve unresolved-type diagnostics quickly. |
| `modelhike/fix` | Attempt supported auto-fixes and return corrected model text plus an audit trail. |
| `modelhike/preflight` | Run a generation-readiness checklist across validation state, module references, and blueprint assignment. |
| `modelhike/list-blueprints` | Show available code-generation blueprints. |
| `modelhike/dsl-schema-in-markdown` | Return the canonical ModelHike DSL specification as markdown. |

### Typical Agent Flow

1. Call `modelhike/dsl-schema-in-markdown` to load the full DSL spec into context.
2. Draft a `.modelhike` model from natural-language intent.
3. Call `modelhike/validate` — iterate on diagnostics until resolved.
4. Call `modelhike/explain` to present the planned architecture to the developer.
5. Call `modelhike/dry-run` to preview the file tree, or `modelhike/generate` to persist output.

Steps 2–3 are the feedback loop. There is no separate `init` command — validation diagnostics guide the agent to a correct model iteratively.

---

## Smart CLI

The CLI exposes the same engine for shell scripting, CI pipelines, and local debugging. Every command maps 1:1 to an MCP tool.

Most CLIs are built for humans — they prompt, confirm, and print text that makes sense to read but is painful to parse. This one is a **smart CLI**: it speaks JSON, exits with meaningful codes, reads from `stdin`, never prompts, and returns structured diagnostics that AI Agents and humans can act on immediately. It is designed to be called 
from code as naturally as it is called from a terminal.

## Example run
To validate a broken model to see diagnostics:

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: 
String\n* owner: CustomerProfile\n' \
  | swift run modelhike validate --input -
```

You'll get back a `W301` diagnostic: `Type 'CustomerProfile' referenced by property 'owner' 
not found.`
You can fix it manually and revalidate, or let `modelhike fix` attempt supported corrections 
first. That feedback loop is the whole point.

## Smart CLI Commands 

```bash
# Validate from stdin
printf '...' | modelhike validate --input -

# Preview one container using the bundled NestJS blueprint
modelhike dry-run --input model.modelhike --blueprint api-nestjs-monorepo --container APIs

# Persist generated output (defaults to ./modelhike-output if --output is omitted)
modelhike generate --input model.modelhike --blueprint api-nestjs-monorepo --container APIs --output ./generated

# Understand before generating
modelhike explain --input model.modelhike --format human

# Dependency tracing
modelhike what-depends-on Payment --input model.modelhike

# Auto-fix supported diagnostics
modelhike fix --input model.modelhike --codes W301

# Check whether a model is ready for generation
modelhike preflight --input model.modelhike --blueprint api-nestjs-monorepo
```

### CLI Properties

- **Human-readable by default.** Pass `--format json` for structured output.
- **Reads from stdin.** Pass `--input -` to pipe model content directly.
- **Stable exit codes.** `0` success · `1` warnings · `2` errors · `3` parse failure · `4` generation failure.
- **No print noise.** Internal logs are suppressed. Stdout is yours.
- **Machine-usable diagnostics.** Every issue has a code, a message, a source location, and a suggestion.

---

## Blueprints

Bundled out of the box — no path configuration needed:

| Blueprint | Output |
|---|---|
| `api-nestjs-monorepo` | NestJS + TypeScript monorepo |
| `api-springboot-monorepo` | Spring Boot reactive monorepo |

Layer in your own with `--blueprints <path>` (CLI) or `MODELHIKE_BLUEPRINTS` (env var).

---

## MCP Dev Tester

An executable target lives under `DevTester_MCP/` for repeatable MCP smoke tests using the official Swift MCP client:

```bash
swift run DevTester_MCP
```

It launches `modelhike-mcp`, runs `initialize`, `tools/list`, and the ModelHike tool calls, then reports pass/fail in pretty or JSON output.

---

## Further Reading

- [`docs/mcp-reference.md`](docs/mcp-reference.md) — MCP tool schemas and configuration
- [`docs/cli-reference.md`](docs/cli-reference.md) — every command, flag, and exit code
- [`docs/smart-cli-philosophy.md`](docs/smart-cli-philosophy.md) — the design principles behind a CLI that serves both humans and agents
- [`docs/architecture.md`](docs/architecture.md) — how the engine works internally
- [`AGENTS.md`](AGENTS.md) — guidance for AI agents working inside this repo
