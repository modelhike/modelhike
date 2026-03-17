import Testing
@testable import ModelHike

@Suite struct PropertyParser_Tests {
    @Test func scalarDefaultsAndConstraintsAreStoredSeparately() async throws {
        let prop = try await parseProperty("* status : String = \"NEW\" { min = 1, max = 10 } (backend)", firstWord: "*")

        #expect(await prop.defaultValue == "\"NEW\"")
        #expect(await prop.validValueSet == nil)
        #expect(await prop.constraints.getString("min") == "1")
        #expect(await prop.constraints.getString("max") == "10")
        #expect(await prop.attribs.has("backend"))
        #expect(await prop.attribs.has("min") == false)
        #expect(await prop.attribs.has("max") == false)
    }

    @Test func collectionDefaultsAreStoredSeparately() async throws {
        let prop = try await parseProperty("- tags : String[*] = <\"vip\", \"beta\"> { max = 10 } (backend)", firstWord: "-")

        #expect(await prop.defaultValue == nil)
        #expect(await prop.validValueSet == "\"vip\", \"beta\"")
        #expect(await prop.constraints.getString("max") == "10")
        #expect(await prop.attribs.has("backend"))
    }

    private func parseProperty(_ line: String, firstWord: String) async throws -> Property {
        let ctx = LoadContext(config: PipelineConfig())
        var pInfo = await ParsedInfo.dummy(line: line, identifier: "PropertyParser_Tests", loadCtx: ctx)
        pInfo.firstWord(firstWord)

        guard let prop = try await Property.parse(pInfo: pInfo) else {
            throw PropertyParserTestError.parseFailed
        }

        return prop
    }
}

private enum PropertyParserTestError: Error {
    case parseFailed
}
