import Foundation
import MCP
import ModelHikeKit

@main
struct ModelHikeMCPServer {
    static func main() async throws {
        let configuration = ServerConfiguration(arguments: CommandLine.arguments)
        let engine = ModelHikeEngine(blueprintsPath: configuration.blueprintsPath)

        let server = Server(
            name: "modelhike",
            version: "1.0.0",
            capabilities: .init(
                tools: .init(listChanged: false)
            )
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: ToolDefinitions.all)
        }

        await server.withMethodHandler(CallTool.self) { params in
            try await ToolRouter.handle(params, engine: engine)
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}

private struct ServerConfiguration {
    let blueprintsPath: String?

    init(arguments: [String]) {
        self.blueprintsPath = Self.parseOption(named: "--blueprints", from: arguments)
            ?? ProcessInfo.processInfo.environment["MODELHIKE_BLUEPRINTS"]
    }

    private static func parseOption(named option: String, from arguments: [String]) -> String? {
        if let index = arguments.firstIndex(of: option), arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }

        let prefix = option + "="
        if let argument = arguments.first(where: { $0.hasPrefix(prefix) }) {
            return String(argument.dropFirst(prefix.count))
        }

        return nil
    }
}
