# ModelHike - Declarative Apps

> **Stop letting AI hallucinate your architecture.** ModelHike provides deterministic code generation through Agent Skills and MCP tools, backed by a true intent compiler. 

---

## 🚀 The Declarative App Paradigm

We used to write code. Then we asked AI to write code for us. But raw source code is the wrong abstraction for AI generation. 

When you ask an AI to generate a backend, you get a massive wall of code. When you ask it to modify that code later, you get a diff full of unintended consequences. There's no stable source of truth, no pure view of the architecture, and no way for the AI to reliably reason about what changed.

**ModelHike introduces the Declarative App.**

Instead of struggling with generated spaghetti code, you and your AI build a declarative model of your application. 

> The AI writes the **model**. ModelHike writes the **code**.

The `.modelhike` file is the ultimate source of truth — a markdown-inspired DSL that sits between natural-language intent and generated production code. It is stable, diffable, and reviewable. Any AI can write to it. ModelHike guarantees the always-deterministic code generation output.

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
```

Containers, modules, entities, properties, methods, references, blueprint tags — all expressed in a lightweight text format that an AI can draft in one shot and a human can read at a glance.

---

## 🤖 AI in the Loop (not Humans)

The tech industry is currently obsessed with "human-in-the-loop" AI generation. This is a frustrating anti-pattern that delegates tedious error-correction and parsing back to *you*. ModelHike flips this. 

The agent drives the *entire* validation and error-correction loop autonomously through JSON tool calls — no shell scripts, no chaotic output parsing, and **no human in the loop** until the final architectural approval.

```text
"I need a subscriptions microservice with Stripe"
               ↓
    AI drafts a .modelhike model
               ↓
  modelhike/validate        →  W301: type 'Plan' not found
               ↓ (AI fixes and retries autonomously)
  modelhike/validate        →  ✓ no issues
               ↓
  modelhike/explain         →  "Here's what I'm about to generate..."
               ↓ (developer finally steps in and approves)
  modelhike/generate        →  deterministic file tree
```

Every tool call returns structured JSON. Every diagnostic carries a stable code, a predictable source location, and machine-actionable suggestions. 

---

## ⚙️ Getting Started

This package provides both an **MCP server** (`modelhike-mcp`) that any MCP-aware agent (Cursor, Windsurf, Claude Code) can call over stdio, and the direct **Smart CLI** (`modelhike`).

**Requirements:** Cross-platform (macOS / Windows / Linux), Swift 6.2 toolchain. Upstream packages (`modelhike-lib`, `modelhike-blueprints`) are resolved automatically via SPM.

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

---

## 🧰 The MCP Tools

The MCP server runs entirely over `stdio` — no HTTP, no complex networking config.

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

---

## 🧠 The Smart CLI

Most CLIs are built for humans — they prompt, confirm, and print text that makes sense to read but is painful to parse. 

The ModelHike CLI is a **Smart CLI**. It speaks JSON natively, exits with meaningful codes, reads from `stdin`, never prompts, and returns structured diagnostics that AI Agents and CI/CD pipelines can act on immediately. It is designed to be called from code as naturally as it is called from a terminal.

### Example Run

To see the engine's diagnostics in action, try validating a broken model:

```bash
printf '===\nAPIs\n====\n+ Billing\n\n=== Billing ===\n\nSubscription\n============\n* _id: String\n* owner: CustomerProfile\n' \
  | swift run modelhike validate --input -
```

You'll instantly get back a `W301` diagnostic: `Type 'CustomerProfile' referenced by property 'owner' not found.` You can fix it and revalidate, or let `modelhike fix` attempt supported corrections first. That feedback loop is the whole point.

### Common CLI Commands

```bash
# Validate from stdin
printf '...' | modelhike validate --input -

# Preview one container using the bundled NestJS blueprint
modelhike dry-run --input model.modelhike --blueprint api-nestjs-monorepo --container APIs

# Persist generated output deterministically (defaults to ./modelhike-output if --output is omitted)
modelhike generate --input model.modelhike --blueprint api-nestjs-monorepo --container APIs --output ./generated

# Understand before generating
modelhike explain --input model.modelhike --format human

# Dependency tracing
modelhike what-depends-on Payment --input model.modelhike

# Auto-fix supported diagnostics in CI
modelhike fix --input model.modelhike --codes W301

# Check whether a model is ready for generation
modelhike preflight --input model.modelhike --blueprint api-nestjs-monorepo
```

- **Zero prompt noise:** Internal logs are suppressed. Stdout is exclusively yours.
- **Stable exit codes:** `0` success · `1` warnings · `2` errors · `3` parse failure · `4` generation failure.
- **Pipeable via stdin:** Pass `--input -` to pipe model content directly.

---

## 🏗️ Bundled Blueprints

Ready for production code generation immediately. Layer in your own custom blueprints via `--blueprints <path>` (CLI) or the `MODELHIKE_BLUEPRINTS` environment variable.

| Blueprint | Output Architecture |
|---|---|
| `api-nestjs-monorepo` | Enterprise NestJS + TypeScript Monorepo |
| `api-springboot-monorepo` | Reactive Spring Boot Microservices |

---

## 📚 Further Reading

- [`docs/cli-reference.md`](docs/cli-reference.md) — Every command, flag, and exit code.
- [`docs/mcp-reference.md`](docs/mcp-reference.md) — MCP tool schemas and configuration.
- [`docs/smart-cli-philosophy.md`](docs/smart-cli-philosophy.md) — The design principles behind an AI-native CLI.
- [`docs/architecture.md`](docs/architecture.md) — How the generative engine works internally.
- [`AGENTS.md`](AGENTS.md) — Guidance for AI agents working inside this specific repo.
