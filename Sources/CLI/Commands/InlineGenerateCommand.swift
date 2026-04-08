import ArgumentParser
import Foundation
import ModelHikeKit

struct InlineGenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inline-generate",
        abstract: "Generate code from an inline model and inline blueprint JSON."
    )

    @Option(name: .long, help: "Model input as a file path or inline .modelhike DSL string.")
    var input: String

    @Option(name: .long, help: "Inline blueprint as a file path or raw JSON string.")
    var inlineBlueprint: String

    @Option(name: .long, help: "Target one or more containers for generation. Repeat as needed.")
    var container: [String] = []

    @Option(name: .long, help: "Optional output directory. When omitted, returns a preview without persisting.")
    var output: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let rendered: String
        let code: ToolExitCode

        do {
            let modelInput = try InlineInputResolver.resolveModelInput(input)
            let blueprint = try InlineInputResolver.resolveInlineBlueprint(inlineBlueprint)
            let engine = ModelHikeEngine()
            let result = try await engine.generateInline(
                modelInput,
                inlineBlueprint: blueprint,
                containers: container,
                persist: output != nil,
                outputPath: output
            )

            rendered = try OutputFormatter.format(result, as: format)
            let hasErrors = DiagnosticSummary(diagnostics: result.diagnostics).hasErrors
            code = result.files.isEmpty && hasErrors
                ? .generationFailure
                : CommandSupport.exitCode(for: result.diagnostics)
        } catch {
            print(CommandSupport.errorOutput(for: error))
            throw ToolExitCode.generationFailure.commandExitCode
        }

        print(rendered)
        if code != .success {
            throw code.commandExitCode
        }
    }
}
