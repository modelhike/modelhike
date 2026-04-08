import Foundation
import ModelHikeKit
import Testing

@Suite("dslSchemaMarkdown")
struct SchemaTests {
    @Test func engineLoadsBundledMarkdown() throws {
        let engine = ModelHikeEngine()
        let schema = try #require(engine.dslSchemaMarkdown())
        #expect(!schema.modelHikeDSL.isEmpty)
        #expect(!schema.codeLogicDSL.isEmpty)
        #expect(!schema.templateSoupDSL.isEmpty)
    }

    @Test func dslMarkdownResultMatchesSchema() throws {
        let engine = ModelHikeEngine()
        let schema = try #require(engine.dslSchemaMarkdown())
        let result = DSLMarkdownSchemaResult(schema)
        #expect(result.modelHikeDSL == schema.modelHikeDSL)
        #expect(result.codeLogicDSL == schema.codeLogicDSL)
        #expect(result.templateSoupDSL == schema.templateSoupDSL)
    }
}
