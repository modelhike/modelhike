# Smart CLI Philosophy

## Why This Exists

Most CLIs are designed around a human at a terminal:

- prompts
- confirmation dialogs
- progressive menus
- prose-only output

That is hostile to automation and awkward for AI agents.

ModelHike Smart CLI is built around a different assumption:

- humans and AI agents should use the same deterministic interface
- the interface should be scriptable, pipeable, and diffable
- the AI should do the creative work, while ModelHike guarantees the deterministic work

## The Core Separation

AI is responsible for:

- interpreting intent
- proposing an architecture
- drafting `.modelhike` content
- responding to diagnostics and revising the model

ModelHike is responsible for:

- parsing the DSL
- validating references and structure
- hydrating the semantic model
- generating deterministic files from blueprints

That split is the product.

## The `.modelhike` File as IR

The `.modelhike` file is the intermediate representation between:

- human intent
- AI reasoning
- deterministic code generation

Because the IR is textual and structured:

- it can be versioned
- it can be diffed
- it can be reviewed before generation
- it can be regenerated repeatedly from the same source

## Why Validation Matters More Than Init

The important operation is not “initialize a project.”

The important operation is:

1. propose a model
2. validate it
3. inspect diagnostics
4. revise it
5. repeat until clean

That loop is what makes the AI “smart” about the DSL.

Example:

- first draft references `User`
- `validate` returns `W301 unresolved type User`
- agent adds `User`
- agent validates again

The validation loop is the actual initialization process.

## Why JSON Matters

JSON remains a first-class CLI output mode because it works for:

- shell scripts
- editors
- CI
- MCP clients
- AI agents

Human-readable output is the default for direct terminal use. JSON remains available with `--format json` for scripts, editors, CI, MCP-adjacent tooling, and AI agents.

## Determinism Over Chatty Magic

This project explicitly avoids:

- hidden interactive state
- prompts
- ad hoc mutation through a REPL-like interface
- generation that cannot be reproduced from inputs

It favors:

- explicit inputs
- explicit outputs
- stable command names
- stable diagnostics
- stable file trees

## How The MCP Layer Fits

MCP is not a different product surface. It is the same surface expressed through tool calls.

The CLI and MCP server share:

- the same engine
- the same result types
- the same validation semantics
- the same blueprint resolution rules

This keeps the product consistent whether it is used:

- from a terminal
- from Cursor
- from another MCP client
- inside a scripted AI workflow

## Product Summary

ModelHike Smart CLI is not “AI codegen.”

It is:

- a deterministic compiler interface for `.modelhike`
- designed for human use
- designed for AI-agent use
- designed to keep architecture discussion natural-language-first while generation stays deterministic
