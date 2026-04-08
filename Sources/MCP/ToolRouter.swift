import Foundation
import MCP
import ModelHikeKit
import ModelHike

enum ToolRouter {
    static func handle(_ params: CallTool.Parameters, engine: ModelHikeEngine) async throws -> CallTool.Result {
        switch params.name {
        case "modelhike/validate":
            let content = requiredString("content", in: params.arguments)
            let result = try await engine.validate(.content(content))
            return try success(result)

        case "modelhike/generate":
            let content = requiredString("content", in: params.arguments)
            let blueprint = requiredString("blueprint", in: params.arguments)
            let outputPath = optionalString("outputPath", in: params.arguments)
            let result = try await engine.generate(.content(content), blueprint: blueprint, outputPath: outputPath)
            return try success(result)

        case "modelhike/dry-run":
            let content = requiredString("content", in: params.arguments)
            let blueprint = requiredString("blueprint", in: params.arguments)
            let result = try await engine.dryRun(.content(content), blueprint: blueprint)
            return try success(result)

        case "modelhike/inline-generate":
            let content = requiredString("content", in: params.arguments)
            let inlineBlueprint: InlineBlueprintSnapshot = try requiredCodable("inlineBlueprint", in: params.arguments)
            let outputPath = optionalString("outputPath", in: params.arguments)
            let result = try await engine.generateInline(
                .content(content),
                inlineBlueprint: inlineBlueprint,
                persist: outputPath != nil,
                outputPath: outputPath
            )
            return try success(result)

        case "modelhike/explain":
            let content = requiredString("content", in: params.arguments)
            let result = try await engine.explain(.content(content))
            return try success(result)

        case "modelhike/inspect":
            let content = requiredString("content", in: params.arguments)
            let entity = requiredString("entity", in: params.arguments)
            let result = try await engine.inspect(.content(content), entity: entity)
            return try success(result)

        case "modelhike/what-depends-on":
            let content = requiredString("content", in: params.arguments)
            let entity = requiredString("entity", in: params.arguments)
            let change = optionalString("change", in: params.arguments)
            let newName = optionalString("newName", in: params.arguments)
            let result = try await engine.whatDependsOn(.content(content), entity: entity, changeKind: change, newName: newName)
            return try success(result)

        case "modelhike/list-blueprints":
            let result = try await engine.listBlueprints()
            return try success(result)

        case "modelhike/list-types":
            let content = requiredString("content", in: params.arguments)
            let result = try await engine.listTypes(.content(content))
            return try success(result)

        case "modelhike/fix":
            let content = requiredString("content", in: params.arguments)
            let codesStr = optionalString("codes", in: params.arguments)
            let codeList = codesStr.map { $0.split(separator: ",").map(String.init) }
            let result = try await engine.fix(.content(content), codes: codeList)
            return try success(result)

        case "modelhike/preflight":
            let content = requiredString("content", in: params.arguments)
            let blueprint = optionalString("blueprint", in: params.arguments)
            let result = try await engine.preflight(.content(content), blueprint: blueprint)
            return try success(result)

        case "modelhike/dsl-schema-in-markdown":
            guard let schema = engine.dslSchemaMarkdown() else {
                return .init(
                    content: [.text(
                        text: "Could not load bundled DSL markdown from the ModelHike package.",
                        annotations: nil,
                        _meta: nil
                    )],
                    structuredContent: nil,
                    isError: true
                )
            }
            return try success(DSLMarkdownSchemaResult(schema))

        default:
            return .init(content: [.text(text: "Unknown tool: \(params.name)", annotations: nil, _meta: nil)], isError: true)
        }
    }

    private static func requiredString(_ key: String, in arguments: [String: Value]?) -> String {
        arguments?[key]?.stringValue ?? ""
    }

    private static func optionalString(_ key: String, in arguments: [String: Value]?) -> String? {
        arguments?[key]?.stringValue
    }

    private static func requiredCodable<T: Decodable>(_ key: String, in arguments: [String: Value]?) throws -> T {
        guard let value = arguments?[key] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Missing required argument '\(key)'")
            throw DecodingError.keyNotFound(InlineCodingKey(stringValue: key), context)
        }
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func success<T: Codable>(_ value: T) throws -> CallTool.Result {
        try .init(
            content: [.text(text: "OK", annotations: nil, _meta: nil)],
            structuredContent: value,
            isError: false
        )
    }
}

private struct InlineCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}
