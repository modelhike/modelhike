import ArgumentParser
import Foundation
import ModelHikeKit

enum OutputFormat: String, ExpressibleByArgument {
    case json
    case human
}

enum OutputFormatter {
    static func format(_ result: ValidationResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            lines.append("Valid: \(result.valid ? "yes" : "no")")
            lines.append("Diagnostics: \(result.summary.total)")
            lines.append("Errors: \(result.summary.errors)")
            lines.append("Warnings: \(result.summary.warnings)")
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: GenerationResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            lines.append(result.persisted ? "Generated files: \(result.summary.fileCount)" : "Preview files: \(result.summary.fileCount)")
            lines.append("Persisted: \(result.persisted ? "yes" : "no")")
            if let outputDirectory = result.outputDirectory {
                lines.append("Output directory: \(outputDirectory)")
            }
            if !result.tree.isEmpty {
                lines.append("")
                lines.append(result.tree)
            }
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: ExplanationResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            lines.append("Containers: \(result.summary.containerCount)")
            lines.append("Modules: \(result.summary.moduleCount)")
            lines.append("Entities: \(result.summary.entityCount)")
            lines.append("Properties: \(result.summary.propertyCount)")
            lines.append("Methods: \(result.summary.methodCount)")
            lines.append("APIs: \(result.summary.apiCount)")
            for container in result.containers {
                lines.append("")
                lines.append("[Container] \(container.displayName) (\(container.containerType))")
                lines.append(contentsOf: formatModules(container.modules, indent: "  "))
            }
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: InspectionResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            if let entity = result.entity {
                lines.append("Entity: \(entity.displayName) (\(entity.kind))")
                if !entity.properties.isEmpty {
                    lines.append("Properties:")
                    lines.append(contentsOf: entity.properties.map { "  - \($0.displayName): \($0.typeName) [\($0.required)]" })
                }
                if !entity.methods.isEmpty {
                    lines.append("Methods:")
                    lines.append(contentsOf: entity.methods.map { "  - \($0.displayName)(\($0.parameters.joined(separator: ", "))) -> \($0.returnType)" })
                }
                if !entity.apis.isEmpty {
                    lines.append("APIs:")
                    lines.append(contentsOf: entity.apis.map { "  - \($0.type): \($0.name)" })
                }
            } else {
                lines.append("Entity not found.")
            }
            if !result.references.isEmpty {
                lines.append("References:")
                lines.append(contentsOf: result.references.map { "  - \($0.entityName).\($0.propertyName) -> \($0.referenceType)" })
            }
            if !result.generatedArtifacts.isEmpty {
                lines.append("Generated artifacts:")
                lines.append(contentsOf: result.generatedArtifacts.map { "  - \($0)" })
            }
            if !result.diagnostics.isEmpty {
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: DependencyResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = ["Entity: \(result.entity)"]
            if result.dependents.isEmpty {
                lines.append("Dependents: none")
            } else {
                lines.append("Dependents:")
                for dependent in result.dependents {
                    lines.append("  - \(dependent.entityName) — \(dependent.location) [kind: \(dependent.referenceKind)]")
                    lines.append("    \(dependent.referenceKind == "tag" || dependent.referenceKind == "annotation" ? "tag/annotation: " : "type: ")\(dependent.rawValue)")
                }
            }
            if !result.breakingChanges.isEmpty {
                lines.append("")
                lines.append("Breaking changes if \(result.entity) is modified:")
                for change in result.breakingChanges {
                    lines.append("  - \(change.fixHint)")
                }
            }
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: BlueprintListResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = ["Blueprints: \(result.blueprints.count)"]
            lines.append(contentsOf: result.blueprints.map { "  - \($0.name)" })
            if !result.diagnostics.isEmpty {
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: TypeListResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            if result.types.isEmpty {
                lines.append("Types: none")
            } else {
                var currentContainer: String?
                var currentModule: String?

                for type in result.types {
                    if type.container != currentContainer {
                        currentContainer = type.container
                        currentModule = nil
                        lines.append("")
                        lines.append("[Container] \(type.container)")
                    }
                    if type.module != currentModule {
                        currentModule = type.module
                        lines.append("  [Module] \(type.module)")
                    }
                    lines.append("    - \(type.name) (\(type.kind))")
                }
            }
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: FixResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            lines.append("Fixed: \(result.fixed ? "yes" : "no")")
            if !result.applied.isEmpty {
                lines.append("Applied fixes: \(result.applied.count)")
                for action in result.applied {
                    lines.append("  - [\(action.code.rawValue)] \(action.action) (line \(action.line))")
                }
            }
            if !result.remaining.isEmpty {
                lines.append("")
                lines.append("Could not fix: \(result.remaining.count)")
                lines.append(contentsOf: formatDiagnostics(result.remaining))
            }
            if let model = result.model, !result.applied.isEmpty {
                lines.append("")
                lines.append("===== Corrected Model =====")
                lines.append(model)
            }
            if !result.diagnostics.isEmpty && result.applied.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    static func format(_ result: PreflightResult, as format: OutputFormat) throws -> String {
        switch format {
        case .json:
            return try encodeJSON(result)
        case .human:
            var lines: [String] = []
            lines.append("Ready: \(result.ready ? "yes" : "no")")
            lines.append("Recommendation: \(result.recommendation)")
            lines.append("")
            lines.append("Preflight checks:")
            for check in result.checks {
                let statusIcon = check.status == "pass" ? "✓" : (check.status == "warn" ? "⚠" : "✗")
                lines.append("  \(statusIcon) \(check.name): \(check.detail)")
                if !check.fixHint.isEmpty {
                    lines.append("    → \(check.fixHint)")
                }
            }
            if !result.diagnostics.isEmpty {
                lines.append("")
                lines.append("Diagnostics:")
                lines.append(contentsOf: formatDiagnostics(result.diagnostics))
            }
            return lines.joined(separator: "\n")
        }
    }

    /// Formats the three canonical DSL markdown documents from `ModelHikeDSLSchema` (upstream bundled resources).
    static func formatDSLMarkdown(_ schema: ModelHikeDSLSchema, as format: OutputFormat) throws -> String {
        let payload = DSLMarkdownSchemaResult(schema)
        switch format {
        case .json:
            return try encodeJSON(payload)
        case .human:
            return """
            ============================
            modelHike.dsl.md
            ============================
            \(schema.modelHikeDSL)

            ---
            ============================
            codelogic.dsl.md
            ============================

            \(schema.codeLogicDSL)

            ---
            ============================
            templatesoup.dsl.md
            ============================
            \(schema.templateSoupDSL)
            """
        }
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        return String(decoding: data, as: UTF8.self)
    }

    private static func formatDiagnostics(_ diagnostics: [Diagnostic]) -> [String] {
        diagnostics.map { diagnostic in
            let code = diagnostic.code.map { "[\($0.rawValue)] " } ?? ""
            let source = diagnostic.source.map { " (\($0.fileIdentifier):\($0.lineNo))" } ?? ""
            return "- \(diagnostic.severity.icon) \(code)\(diagnostic.message)\(source)"
        }
    }

    private static func formatModules(_ modules: [ModuleSummary], indent: String) -> [String] {
        var lines: [String] = []
        for module in modules {
            lines.append("\(indent)[Module] \(module.displayName)")
            for object in module.objects {
                lines.append("\(indent)  - \(object.displayName) (\(object.kind))")
            }
            lines.append(contentsOf: formatModules(module.submodules, indent: indent + "  "))
        }
        return lines
    }
}
