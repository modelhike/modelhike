import ArgumentParser
import Foundation
import ModelHikeKit

struct PreflightCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preflight",
        abstract: "Pre-generation readiness check combining validate + blueprint checks."
    )

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Optional blueprint name to check against.")
    var blueprint: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine()
            let result = try await engine.preflight(modelInput, blueprint: blueprint)
            output = try OutputFormatter.format(result, as: format)
            code = result.ready ? .success : .validationWarnings
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
