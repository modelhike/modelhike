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

    @Test func predicateConstraintsCanUseComparisons() async throws {
        let prop = try await parseProperty("* salary : Int { salary > 0 }", firstWord: "*")
        let constraints = await prop.constraints.snapshot()

        #expect(constraints.count == 1)
        #expect(constraints[0].name == nil)
        #expect(ConstraintRenderer.render(constraints[0]) == "salary > 0")
    }

    @Test func mixedNamedAndPredicateConstraintsBothParse() async throws {
        let prop = try await parseProperty("* salary : Int { min = 0, salary > bonus } (backend)", firstWord: "*")
        let constraints = await prop.constraints.snapshot()

        #expect(constraints.count == 2)
        #expect(await prop.constraints.getString("min") == "0")
        #expect(constraints.contains(where: { $0.name == nil && ConstraintRenderer.render($0) == "salary > bonus" }))
        #expect(await prop.attribs.has("backend"))
    }

    @Test func wrapperKeepsLegacyConstraintLookupAndExposesStructuredList() async throws {
        let prop = try await parseProperty("* salary : Int { min = 0, salary > bonus }", firstWord: "*")
        let wrapper = TypeProperty_Wrap(prop)
        let pInfo = await ParsedInfo.dummy(line: "", identifier: "PropertyParser_Tests", loadCtx: LoadContext(config: PipelineConfig()))

        let legacyValue = try await wrapper.getValueOf(property: "constraint-min", with: pInfo) as? String
        let structured = try await wrapper.getValueOf(property: "constraints", with: pInfo) as? [Constraint_Wrap]

        #expect(legacyValue == "0")
        let rendered = try await structured?.asyncThrowingMap { try await $0.getValueOf(property: "rendered", with: pInfo) as? String } ?? []
        #expect(rendered == ["min = 0", "salary > bonus"])
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

