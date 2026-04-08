import Foundation

/// Codable payload for MCP/JSON: the three canonical DSL markdown documents from `ModelHikeDSLSchema`.
public struct DSLMarkdownSchemaResult: Codable, Sendable {
    public let modelHikeDSL: String
    public let codeLogicDSL: String
    public let templateSoupDSL: String

    public init(modelHikeDSL: String, codeLogicDSL: String, templateSoupDSL: String) {
        self.modelHikeDSL = modelHikeDSL
        self.codeLogicDSL = codeLogicDSL
        self.templateSoupDSL = templateSoupDSL
    }

    public init(_ schema: ModelHikeDSLSchema) {
        self.modelHikeDSL = schema.modelHikeDSL
        self.codeLogicDSL = schema.codeLogicDSL
        self.templateSoupDSL = schema.templateSoupDSL
    }
}
