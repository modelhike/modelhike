import Foundation
import MCP

enum ToolDefinitions {
    static let all: [Tool] = [
        Tool(
            name: "modelhike/validate",
            description: "Validate .modelhike model content and return structured diagnostics.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content to validate"),
                    ]),
                ]),
                "required": .array([.string("content")]),
            ])
        ),
        Tool(
            name: "modelhike/generate",
            description: "Generate code from validated .modelhike model content, persist it to disk, and return the generated file manifest.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string("Validated .modelhike DSL content"),
                    ]),
                    "blueprint": .object([
                        "type": .string("string"),
                        "description": .string("Blueprint name"),
                    ]),
                    "outputPath": .object([
                        "type": .string("string"),
                        "description": .string("Optional output directory. Defaults to '<cwd>/modelhike-output' for inline content."),
                    ]),
                ]),
                "required": .array([.string("content"), .string("blueprint")]),
            ])
        ),
        Tool(
            name: "modelhike/dry-run",
            description: "Preview generated files from validated .modelhike model content without persisting them.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string("Validated .modelhike DSL content"),
                    ]),
                    "blueprint": .object([
                        "type": .string("string"),
                        "description": .string("Blueprint name"),
                    ]),
                ]),
                "required": .array([.string("content"), .string("blueprint")]),
            ])
        ),
        Tool(
            name: "modelhike/inline-generate",
            description: "Generate code from inline .modelhike content and an inline blueprint JSON object.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content"),
                    ]),
                    "inlineBlueprint": .object([
                        "type": .string("object"),
                        "properties": .object([
                            "name": .object([
                                "type": .string("string"),
                            ]),
                            "scripts": .object([
                                "type": .string("object"),
                            ]),
                            "templates": .object([
                                "type": .string("object"),
                            ]),
                            "folders": .object([
                                "type": .string("object"),
                            ]),
                            "modifiers": .object([
                                "type": .string("object"),
                            ]),
                        ]),
                        "required": .array([.string("name"), .string("scripts")]),
                    ]),
                    "outputPath": .object([
                        "type": .string("string"),
                        "description": .string("Optional output directory. When omitted, returns a preview without persisting."),
                    ]),
                ]),
                "required": .array([.string("content"), .string("inlineBlueprint")]),
            ])
        ),
        Tool(
            name: "modelhike/explain",
            description: "Explain the architecture represented by .modelhike model content.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content to explain"),
                    ]),
                ]),
                "required": .array([.string("content")]),
            ])
        ),
        Tool(
            name: "modelhike/inspect",
            description: "Inspect one entity in a .modelhike model.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content"),
                    ]),
                    "entity": .object([
                        "type": .string("string"),
                        "description": .string("Entity name to inspect"),
                    ]),
                ]),
                "required": .array([.string("content"), .string("entity")]),
            ])
        ),
        Tool(
            name: "modelhike/what-depends-on",
            description: "Show all entities that depend on a target entity. Optionally compute breaking changes for rename/remove operations.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content"),
                    ]),
                    "entity": .object([
                        "type": .string("string"),
                        "description": .string("Entity name to analyze"),
                    ]),
                    "change": .object([
                        "type": .string("string"),
                        "description": .string("Optional change kind: 'rename' or 'remove'"),
                    ]),
                    "newName": .object([
                        "type": .string("string"),
                        "description": .string("New name for rename operations"),
                    ]),
                ]),
                "required": .array([.string("content"), .string("entity")]),
            ])
        ),
        Tool(
            name: "modelhike/list-blueprints",
            description: "List all available ModelHike blueprints.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
            ])
        ),
        Tool(
            name: "modelhike/list-types",
            description: "List all type names declared in the model, organized by module and container.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content"),
                    ]),
                ]),
                "required": .array([.string("content")]),
            ])
        ),
        Tool(
            name: "modelhike/fix",
            description: "Auto-repair model diagnostics and return corrected model content.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content to fix"),
                    ]),
                    "codes": .object([
                        "type": .string("string"),
                        "description": .string("Optional comma-separated diagnostic codes to fix (e.g., 'W301,W307')"),
                    ]),
                ]),
                "required": .array([.string("content")]),
            ])
        ),
        Tool(
            name: "modelhike/preflight",
            description: "Pre-generation readiness check combining validate + blueprint checks.",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "content": .object([
                        "type": .string("string"),
                        "description": .string(".modelhike DSL content to check"),
                    ]),
                    "blueprint": .object([
                        "type": .string("string"),
                        "description": .string("Optional blueprint name to verify"),
                    ]),
                ]),
                "required": .array([.string("content")]),
            ])
        ),
        Tool(
            name: "modelhike/dsl-schema-in-markdown",
            description: """
            Return the full canonical ModelHike DSL documentation as markdown: three bundled spec files \
            (modelHike.dsl.md, codelogic.dsl.md, templatesoup.dsl.md) as JSON string fields. Use before \
            drafting or editing .modelhike models.
            """,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
            ])
        ),
    ]
}
