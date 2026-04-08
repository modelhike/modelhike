import ArgumentParser
import Foundation
import ModelHikeKit

struct WhatDependsOnCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "what-depends-on",
        abstract: "Show reverse dependencies for an entity."
    )

    @Argument(help: "Entity name to inspect.")
    var entity: String

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Change kind to compute breaking changes: 'rename' or 'remove'. Optional.")
    var change: String?

    @Option(name: .long, help: "New name for the entity (used with --change rename).")
    var newName: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine()
            let result = try await engine.whatDependsOn(modelInput, entity: entity, changeKind: change, newName: newName)
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
