import ArgumentParser
import Foundation
import ModelHikeKit

struct ListBlueprintsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-blueprints",
        abstract: "List all available code-generation blueprints."
    )

    @Option(name: .long, help: "Blueprints directory path.")
    var blueprints: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let engine = ModelHikeEngine(blueprintsPath: blueprints)
            let result = try await engine.listBlueprints()
            output = try OutputFormatter.format(result, as: format)
            code = CommandSupport.exitCode(for: result.diagnostics)
        } catch {
            print(CommandSupport.errorOutput(for: error))
            throw ToolExitCode.generationFailure.commandExitCode
        }

        print(output)
        if code != .success {
            throw code.commandExitCode
        }
    }
}
