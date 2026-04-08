import ArgumentParser
import Foundation
import ModelHikeKit

struct FixCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fix",
        abstract: "Auto-repair model diagnostics and return corrected model content."
    )

    @Option(name: .long, help: "Model input: file path, directory, or '-' for stdin.")
    var input: String?

    @Option(name: .long, help: "Comma-separated diagnostic codes to fix (e.g., W301,W307). If omitted, all fixable diagnostics are attempted.")
    var codes: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let output: String
        let code: ToolExitCode

        do {
            let modelInput = try InputResolver.resolve(input: input)
            let engine = ModelHikeEngine()
            let codeList = codes.map { $0.split(separator: ",").map(String.init) }
            let result = try await engine.fix(modelInput, codes: codeList)
            output = try OutputFormatter.format(result, as: format)
            code = result.fixed ? .success : .validationWarnings
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
