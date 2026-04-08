import ArgumentParser
import Foundation
import ModelHikeKit

struct DryRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dry-run",
        abstract: "Preview generated files without persisting them."
    )

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Optional blueprint name to override any '#blueprint(name)' tag in the model.")
    var blueprint: String?

    @Option(name: .long, help: "Target one or more containers for generation (including composite / container-group containers). Repeat as needed.")
    var container: [String] = []

    @Option(name: .long, help: "Target one or more system views for generation. Repeat as needed.")
    var systemView: [String] = []

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    @Option(name: .long, help: "Blueprints directory path.")
    var blueprints: String?

    mutating func run() async throws {
        let rendered: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine(blueprintsPath: blueprints)
            let result = try await engine.dryRun(
                modelInput,
                blueprint: blueprint,
                containers: container,
                systemViews: systemView
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
