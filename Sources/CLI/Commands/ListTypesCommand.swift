import ArgumentParser
import Foundation
import ModelHikeKit

struct ListTypesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-types",
        abstract: "List all type names declared in the model, organized by module and container."
    )

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine()
            let result = try await engine.listTypes(modelInput)
            output = try OutputFormatter.format(result, as: format)
            code = CommandSupport.exitCode(for: result.diagnostics)
        } catch {
            print(CommandSupport.errorOutput(for: error))
            throw ToolExitCode.parseFailure.commandExitCode
        }

        print(output)
        if code != .success {
            throw code.commandExitCode
        }
    }
}
