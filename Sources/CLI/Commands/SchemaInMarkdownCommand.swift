import ArgumentParser
import Foundation
import ModelHikeKit

struct SchemaInMarkdownCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dsl-schema-in-markdown",
        abstract: "Print the canonical ModelHike DSL documentation as markdown (three bundled spec files)."
    )

    @Option(name: .long, help: "Output format: human concatenates all docs with headings; json returns three string fields.")
    var format: OutputFormat = .human

    mutating func run() async throws {
        let engine = ModelHikeEngine()
        guard let schema = engine.dslSchemaMarkdown() else {
            print(CommandSupport.errorOutput(for: SchemaInMarkdownError.bundleUnavailable))
            throw ToolExitCode.generationFailure.commandExitCode
        }
        let output = try OutputFormatter.formatDSLMarkdown(schema, as: format)
        print(output)
    }
}

private enum SchemaInMarkdownError: LocalizedError {
    case bundleUnavailable

    var errorDescription: String? {
        switch self {
        case .bundleUnavailable:
            return "Could not load bundled DSL markdown from the ModelHike package (resource bundle missing or unreadable)."
        }
    }
}
