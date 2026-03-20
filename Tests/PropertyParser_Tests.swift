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

    @Test func validValueSetWithoutEqualsParsesSeparately() async throws {
        let prop = try await parseProperty("- tags : String[*] <\"vip\", \"beta\"> { max = 10 } (backend)", firstWord: "-")

        #expect(await prop.defaultValue == nil)
        #expect(await prop.validValueSet == "\"vip\", \"beta\"")
        #expect(await prop.constraints.getString("max") == "10")
        #expect(await prop.attribs.has("backend"))
    }

    @Test func validValueSetAndDefaultCanCoexist() async throws {
        let prop = try await parseProperty("* status : String = \"NEW\" <\"NEW\", \"ACTIVE\", \"DONE\">", firstWord: "*")

        #expect(await prop.validValueSet == "\"NEW\", \"ACTIVE\", \"DONE\"")
        #expect(await prop.defaultValue == "\"NEW\"")
    }

    @Test func validValueSetWithEqualsIsRejected() async throws {
        let prop = try await parsePropertyIfPossible("- tags : String[*] = <\"vip\", \"beta\">", firstWord: "-")

        #expect(prop == nil)
    }

    @Test func validValueSetAfterDefaultIsRequiredWhenBothExist() async throws {
        let prop = try await parsePropertyIfPossible("* status : String <\"NEW\", \"ACTIVE\", \"DONE\"> = \"NEW\"", firstWord: "*")

        #expect(prop == nil)
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

    @Test func primaryKeyPrefixMarksRequiredPrimaryKey() async throws {
        let prop = try await parseProperty("** orderId : Int", firstWord: "**")

        #expect(await prop.required == .yes)
        #expect(await prop.isObjectID)
        #expect(await prop.type.kind == .int)
    }

    @Test func refTypeWithQuotedTargetAndFieldParses() async throws {
        let prop = try await parseProperty("* departmentId : Ref@\"Department Lookup\".departmentId", firstWord: "*")

        #expect(await prop.type.kind == .reference(.init(targetName: "Department Lookup", fieldName: "departmentId")))
    }

    @Test func refTypeResolvesReferencedFieldTypeFromLoadedModel() async throws {
        let dsl = """
            ===
            Company
            ===
            + HR

            === HR ===

            Department Lookup
            =================
            ** departmentId : Int
            * name : String

            Backup Department
            =================
            ** backupId : String

            Employee
            ========
            * departmentId : Ref@"Department Lookup".departmentId
            * departmentLink : ExtendedReference@"Department Lookup".departmentId
            * departmentChoices : Reference@"Department Lookup".departmentId,"Backup Department".backupId
            """

        let ctx = LoadContext(config: PipelineConfig())
        let modelSpace = try await ModelFileParser(with: ctx).parse(string: dsl, identifier: "PropertyParser_Tests")
        await ctx.model.append(contentsOf: modelSpace)
        try await ctx.model.resolveAndLinkItems(with: ctx)

        let employee = try #require(await ctx.model.types.get(for: "Employee"))
        let departmentId = try #require(await employee.getProp("departmentId"))
        let departmentLink = try #require(await employee.getProp("departmentLink"))
        let departmentChoices = try #require(await employee.getProp("departmentChoices"))

        #expect(
            await departmentId.type.kind == .reference(
                .init(targetName: "DepartmentLookup", fieldName: "departmentId")
            )
        )
        #expect(
            await departmentLink.type.kind == .extendedReference(
                .init(targetName: "DepartmentLookup", fieldName: "departmentId")
            )
        )
        #expect(
            await departmentChoices.type.kind == .multiReference([
                .init(targetName: "DepartmentLookup", fieldName: "departmentId"),
                .init(targetName: "BackupDepartment", fieldName: "backupId"),
            ])
        )

        let departmentIdReference = try #require((await departmentId.type.kind).firstReferenceTarget)
        let departmentIdField = try #require(departmentIdReference.fieldProperty)
        #expect(await departmentIdField.type.typeNameString_ForDebugging() == "Int")

        let departmentLinkReference = try #require((await departmentLink.type.kind).firstReferenceTarget)
        let departmentLinkField = try #require(departmentLinkReference.fieldProperty)
        #expect(await departmentLinkField.type.typeNameString_ForDebugging() == "Int")

        let departmentChoiceReferences = try #require((await departmentChoices.type.kind).referenceTargets)
        #expect(departmentChoiceReferences.count == 2)
        let firstChoiceField = try #require(departmentChoiceReferences[0].fieldProperty)
        let secondChoiceField = try #require(departmentChoiceReferences[1].fieldProperty)
        #expect(await firstChoiceField.type.typeNameString_ForDebugging() == "Int")
        #expect(await secondChoiceField.type.typeNameString_ForDebugging() == "String")
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

    private func parsePropertyIfPossible(_ line: String, firstWord: String) async throws -> Property? {
        let ctx = LoadContext(config: PipelineConfig())
        var pInfo = await ParsedInfo.dummy(line: line, identifier: "PropertyParser_Tests", loadCtx: ctx)
        pInfo.firstWord(firstWord)
        return try await Property.parse(pInfo: pInfo)
    }
}

private enum PropertyParserTestError: Error {
    case parseFailed
}

