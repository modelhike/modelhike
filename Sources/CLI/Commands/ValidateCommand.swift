import ArgumentParser
import Foundation
import ModelHikeKit

struct ValidateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate model content and return structured diagnostics."
    )

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    @Option(name: .long, help: "Blueprints directory path.")
    var blueprints: String?

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine(blueprintsPath: blueprints)
            let result = try await engine.validate(modelInput)
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
