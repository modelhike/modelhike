import Testing
@testable import ModelHike

// MARK: - BlueprintModifierInputType unit tests

@Suite("BlueprintModifierInputType") struct BlueprintModifierInputType_Tests {

    // MARK: init(string:)

    @Test func knownTypes() {
        #expect(BlueprintModifierInputType(string: "String") == .string)
        #expect(BlueprintModifierInputType(string: "Double") == .double)
        #expect(BlueprintModifierInputType(string: "Bool")   == .bool)
        #expect(BlueprintModifierInputType(string: "Array")  == .array)
        #expect(BlueprintModifierInputType(string: "Object") == .object)
        #expect(BlueprintModifierInputType(string: "Any")    == .any)
    }

    @Test func nilFallsBackToAny() {
        #expect(BlueprintModifierInputType(string: nil) == .any)
    }

    @Test func emptyStringFallsBackToAny() {
        #expect(BlueprintModifierInputType(string: "") == .any)
    }

    @Test func unrecognisedStringFallsBackToAny() {
        #expect(BlueprintModifierInputType(string: "unknown") == .any)
        #expect(BlueprintModifierInputType(string: "string")  == .any)  // case-sensitive
        #expect(BlueprintModifierInputType(string: "INTEGER") == .any)
    }

    // MARK: accepts(_:)

    @Test func stringAcceptsStringOnly() {
        #expect( BlueprintModifierInputType.string.accepts("hello"))
        #expect(!BlueprintModifierInputType.string.accepts(42.0))
        #expect(!BlueprintModifierInputType.string.accepts(true))
    }

    @Test func doubleAcceptsDoubleOnly() {
        #expect( BlueprintModifierInputType.double.accepts(3.14))
        #expect(!BlueprintModifierInputType.double.accepts("3.14"))
        #expect(!BlueprintModifierInputType.double.accepts(true))
    }

    @Test func boolAcceptsBoolOnly() {
        #expect( BlueprintModifierInputType.bool.accepts(true))
        #expect(!BlueprintModifierInputType.bool.accepts("true"))
        #expect(!BlueprintModifierInputType.bool.accepts(1.0))
    }

    @Test func arrayAcceptsArrayOnly() {
        let arr: [Sendable] = ["a", "b"]
        #expect( BlueprintModifierInputType.array.accepts(arr))
        #expect(!BlueprintModifierInputType.array.accepts("not an array"))
    }

    @Test func objectAndAnyAcceptEverything() {
        #expect(BlueprintModifierInputType.object.accepts("value"))
        #expect(BlueprintModifierInputType.object.accepts(42.0))
        #expect(BlueprintModifierInputType.any.accepts("value"))
        #expect(BlueprintModifierInputType.any.accepts(99.0))
        #expect(BlueprintModifierInputType.any.accepts(false))
    }
}

// MARK: - FrontMatter.parse unit tests

@Suite("FrontMatter.parse") struct FrontMatter_Parse_Tests {

    @Test func noFrontMatter_returnsEmptyValuesAndOriginalBody() {
        let input = "just a template body"
        let (values, body) = FrontMatter.parse(contents: input)
        #expect(values.isEmpty)
        #expect(body == input)
    }

    @Test func emptyContent() {
        let (values, body) = FrontMatter.parse(contents: "")
        #expect(values.isEmpty)
        #expect(body == "")
    }

    @Test func simpleKeyValuePairs() {
        let input = """
            ---
            input: value
            type: String
            ---
            template body
            """
        let (values, body) = FrontMatter.parse(contents: input)
        #expect(values["input"] == "value")
        #expect(values["type"]  == "String")
        #expect(body.contains("template body"))
    }

    @Test func paramsKey() {
        let input = """
            ---
            params: prefix, suffix
            ---
            body
            """
        let (values, _) = FrontMatter.parse(contents: input)
        #expect(values["params"] == "prefix, suffix")
    }

    @Test func onlyFrontMatterNoBody() {
        let input = """
            ---
            input: val
            ---
            """
        let (values, body) = FrontMatter.parse(contents: input)
        #expect(values["input"] == "val")
        #expect(body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test func bodyPreservedVerbatim() {
        let input = """
            ---
            input: x
            ---
            line1
            line2
            """
        let (_, body) = FrontMatter.parse(contents: input)
        #expect(body.contains("line1"))
        #expect(body.contains("line2"))
    }
}

// MARK: - InlineBlueprint unit tests

@Suite("InlineBlueprint") struct InlineBlueprint_Tests {

    // Shared loader for structural tests
    let loader = InlineBlueprint(name: "test-blueprint") {
        InlineScript("main", contents: ":render file \"Entity.teso\"")
        InlineTemplate("Entity", contents: "class {{ entity.name }} {}")
        InlineTemplate("EntityList", in: "_root_", contents: "// list file")
        InlineModifier("shout", contents: "{{ value | uppercase }}")
        InlineFolder("helpers") {
            InlineTemplate("Util", contents: "// util")
            InlineTemplate("Base", contents: "// base")
        }
    }

    // MARK: Identity

    @Test func blueprintNameIsPreserved() async {
        let name = await loader.blueprintName
        #expect(name == "test-blueprint")
    }

    @Test func blueprintExistsAlwaysTrue() async throws {
        #expect(try await loader.exists())
    }

    // MARK: loadTemplate

    @Test func loadTemplate_found() async throws {
        let pInfo = await makePInfo()
        let template = try await loader.loadTemplate(fileName: "Entity", with: pInfo)
        #expect(template.name == "Entity")
        #expect(template.toString() == "class {{ entity.name }} {}")
    }

    @Test func loadTemplate_notFound_throws() async throws {
        let pInfo = await makePInfo()
        await #expect(throws: (any Error).self) {
            try await loader.loadTemplate(fileName: "NonExistent", with: pInfo)
        }
    }

    // MARK: loadScriptFile

    @Test func loadScriptFile_found() async throws {
        let pInfo = await makePInfo()
        let script = try await loader.loadScriptFile(fileName: "main", with: pInfo)
        #expect(script.toString() == ":render file \"Entity.teso\"")
    }

    @Test func loadScriptFile_notFound_throws() async throws {
        let pInfo = await makePInfo()
        await #expect(throws: (any Error).self) {
            try await loader.loadScriptFile(fileName: "nonexistent", with: pInfo)
        }
    }

    // MARK: hasFolder

    @Test func hasFolder_existing() async {
        #expect(await loader.hasFolder("_root_"))
        #expect(await loader.hasFolder("helpers"))
        #expect(await loader.hasFolder(SpecialFolderNames.modifiers))
    }

    @Test func hasFolder_nonExisting() async {
        #expect(await !loader.hasFolder("nonexistent"))
        #expect(await !loader.hasFolder("_modifiers_2"))
    }

    // MARK: listFiles

    @Test func listFiles_rootLevelContainsTemplateAndScript() async {
        let files = await loader.listFiles(inFolder: "")
        #expect(files.contains("Entity.teso"))
        #expect(files.contains("main.ss"))
    }

    @Test func listFiles_specialFolder() async {
        let files = await loader.listFiles(inFolder: "_root_")
        #expect(files.contains("EntityList.teso"))
    }

    @Test func listFiles_modifiersFolder() async {
        let files = await loader.listFiles(inFolder: SpecialFolderNames.modifiers)
        #expect(files.contains("shout.teso"))
    }

    @Test func listFiles_inlineFolder_allFilesPresent() async {
        let files = await loader.listFiles(inFolder: "helpers")
        #expect(Set(files) == Set(["Util.teso", "Base.teso"]))
    }

    @Test func listFiles_nonExistingFolder_isEmpty() async {
        let files = await loader.listFiles(inFolder: "nonexistent")
        #expect(files.isEmpty)
    }

    // MARK: readTextContents

    @Test func readTextContents_rootFile() async throws {
        let pInfo = await makePInfo()
        let contents = try await loader.readTextContents(filename: "main.ss", with: pInfo)
        #expect(contents == ":render file \"Entity.teso\"")
    }

    @Test func readTextContents_nestedFile() async throws {
        let pInfo = await makePInfo()
        let contents = try await loader.readTextContents(
            filename: "\(SpecialFolderNames.modifiers)/shout.teso", with: pInfo)
        #expect(contents == "{{ value | uppercase }}")
    }

    @Test func readTextContents_notFound_throws() async throws {
        let pInfo = await makePInfo()
        await #expect(throws: (any Error).self) {
            try await loader.readTextContents(filename: "ghost.txt", with: pInfo)
        }
    }

    // MARK: InlineFolder grouping

    @Test func inlineFolder_filesInCorrectFolder() async {
        let folderFiles = await loader.listFiles(inFolder: "helpers")
        #expect(folderFiles.count == 2)
        // should NOT appear in root
        let rootFiles = await loader.listFiles(inFolder: "")
        #expect(!rootFiles.contains("Util.teso"))
    }

    // MARK: InlineModifier shorthand

    @Test func inlineModifier_landsInModifiersFolder() async {
        let modFiles = await loader.listFiles(inFolder: SpecialFolderNames.modifiers)
        #expect(modFiles == ["shout.teso"])
    }

    // MARK: Helpers

    private func makePInfo() async -> ParsedInfo {
        let ctx = LoadContext(config: PipelineConfig())
        return await ParsedInfo.dummy(line: "", identifier: "test", loadCtx: ctx)
    }
}

// MARK: - BlueprintModifierLoader unit tests

@Suite("BlueprintModifierLoader") struct BlueprintModifierLoader_Tests {

    // MARK: No modifiers folder

    @Test func noModifiersFolder_returnsEmpty() async throws {
        let blueprint = InlineBlueprint(name: "no-mods") {
            InlineScript("main", contents: "")
        }
        let sandbox = await makeSandbox()
        let pInfo   = await makePInfo(sandbox)
        let result  = try await BlueprintModifierLoader.loadModifiers(
            from: blueprint, templateSoup: sandbox.templateSoup, with: pInfo)
        #expect(result.isEmpty)
    }

    // MARK: No-param modifier (default input var, default type)

    @Test func noFrontMatter_createsWithoutParamsModifier() async throws {
        let blueprint = InlineBlueprint(name: "test") {
            InlineModifier("exclaim", contents: "{{ value }}!")
        }
        let mods = try await loadModifiers(from: blueprint)
        #expect(mods.count == 1)
        #expect(mods[0].name == "exclaim")
        #expect(mods[0] is BlueprintModifierWithoutParams)
    }

    @Test func withParamsFrontMatter_createsWithParamsModifier() async throws {
        let blueprint = InlineBlueprint(name: "test") {
            InlineModifier("wrap", contents: """
                ---
                params: prefix, suffix
                ---
                {{ prefix }}{{ value }}{{ suffix }}
                """)
        }
        let mods = try await loadModifiers(from: blueprint)
        #expect(mods.count == 1)
        #expect(mods[0].name == "wrap")
        #expect(mods[0] is BlueprintModifierWithParams)
    }

    @Test func nonTesoFilesIgnored() async throws {
        // InlineScript adds a ".ss" extension — it should be silently skipped by the loader
        let blueprint = InlineBlueprint(name: "test") {
            InlineScript("not-a-modifier", in: SpecialFolderNames.modifiers, contents: "// script")
            InlineModifier("real", contents: "{{ value }}")
        }
        let mods = try await loadModifiers(from: blueprint)
        #expect(mods.count == 1)
        #expect(mods[0].name == "real")
    }

    @Test func multipleModifiersAllLoaded() async throws {
        let blueprint = InlineBlueprint(name: "test") {
            InlineModifier("upper", contents: "{{ value | uppercase }}")
            InlineModifier("lower", contents: "{{ value | lowercase }}")
            InlineModifier("bang",  contents: "{{ value }}!")
        }
        let mods = try await loadModifiers(from: blueprint)
        #expect(mods.count == 3)
        let names = Set(mods.map { $0.name })
        #expect(names == Set(["upper", "lower", "bang"]))
    }

    @Test func customInputVarName_parsedFromFrontMatter() async throws {
        let blueprint = InlineBlueprint(name: "test") {
            InlineModifier("tagged", contents: """
                ---
                input: item
                ---
                [{{ item }}]
                """)
        }
        let mods = try await loadModifiers(from: blueprint)
        #expect(mods.count == 1)
        #expect(mods[0] is BlueprintModifierWithoutParams)
    }

    // MARK: Helpers

    private func makeSandbox() async -> CodeGenerationSandbox {
        await CodeGenerationSandbox(model: LoadContext(config: PipelineConfig()).model,
                                    config: PipelineConfig())
    }

    private func makePInfo(_ sandbox: CodeGenerationSandbox) async -> ParsedInfo {
        await ParsedInfo.dummy(line: "", identifier: "test", generationCtx: sandbox.context)
    }

    private func loadModifiers(from blueprint: InlineBlueprint) async throws -> [Modifier] {
        let sandbox = await makeSandbox()
        let pInfo   = await makePInfo(sandbox)
        return try await BlueprintModifierLoader.loadModifiers(
            from: blueprint, templateSoup: sandbox.templateSoup, with: pInfo)
    }
}

// MARK: - Blueprint modifier E2E rendering tests

@Suite("Blueprint Modifier E2E") struct BlueprintModifier_E2E_Tests {

    // MARK: No-param modifiers

    @Test func simpleModifier_appliedToStringValue() async throws {
        let result = try await render(
            "{{ greeting | shout }}",
            data: ["greeting": "hello"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("shout", contents: "{{ value | uppercase }}")
            })
        #expect(result == "HELLO")
    }

    @Test func modifierAppendsStaticText() async throws {
        let result = try await render(
            "{{ name | exclaim }}",
            data: ["name": "World"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("exclaim", contents: "{{ value }}!")
            })
        #expect(result == "World!")
    }

    @Test func modifierWithCustomInputVariable() async throws {
        let result = try await render(
            "{{ word | bracket }}",
            data: ["word": "swift"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("bracket", contents: """
                    ---
                    input: str
                    ---
                    [{{ str }}]
                    """)
            })
        #expect(result == "[swift]")
    }

    @Test func modifierWithConditionalTemplate() async throws {
        let resultTrue = try await render(
            "{{ flag | yesno }}",
            data: ["flag": true],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("yesno", contents: """
                    ---
                    input: flag
                    type: Bool
                    ---
                    : if flag
                    yes
                    : else
                    no
                    : end-if
                    """)
            })
        #expect(resultTrue == "yes")

        let resultFalse = try await render(
            "{{ flag | yesno }}",
            data: ["flag": false],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("yesno", contents: """
                    ---
                    input: flag
                    type: Bool
                    ---
                    : if flag
                    yes
                    : else
                    no
                    : end-if
                    """)
            })
        #expect(resultFalse == "no")
    }

    // MARK: Modifiers with params

    @Test func paramModifier_singleParam() async throws {
        // Note: commas inside string literals are treated as argument separators by the
        // template engine, so we use a comma-free literal "Mr " here.
        let result = try await render(
            "{{ name | prefix(\"Mr \") }}",
            data: ["name": "Smith"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("prefix", contents: """
                    ---
                    params: pre
                    ---
                    {{ pre }}{{ value }}
                    """)
            })
        #expect(result == "Mr Smith")
    }

    @Test func paramModifier_twoParams() async throws {
        let result = try await render(
            "{{ word | surround(\"[\", \"]\") }}",
            data: ["word": "test"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("surround", contents: """
                    ---
                    params: open, close
                    ---
                    {{ open }}{{ value }}{{ close }}
                    """)
            })
        #expect(result == "[test]")
    }

    // MARK: Type-restricted modifiers

    @Test func typeRestricted_correctType_succeeds() async throws {
        let result = try await render(
            "{{ msg | shout }}",
            data: ["msg": "hello"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("shout", contents: """
                    ---
                    type: String
                    ---
                    {{ value | uppercase }}
                    """)
            })
        #expect(result == "HELLO")
    }

    @Test func typeRestricted_wrongType_throwsError() async throws {
        let blueprint = InlineBlueprint(name: "test") {
            InlineModifier("stringOnly", contents: """
                ---
                type: String
                ---
                {{ value }}
                """)
        }
        await #expect(throws: (any Error).self) {
            try await render("{{ num | stringOnly }}", data: ["num": 42.0], blueprint: blueprint)
        }
    }

    // MARK: Modifier chaining

    @Test func chainTwoBlueprintModifiers() async throws {
        // Multiple modifiers are chained with '+' inside {{ }} expressions.
        // Each blueprint modifier is rendered by the template engine, which appends a newline
        // to every output line. When chained, the intermediate newline is embedded inside the
        // next modifier's output, so we normalise before comparing.
        let result = try await render(
            "{{ word | bracket + exclaim }}",
            data: ["word": "swift"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("bracket",  contents: "[{{ value }}]")
                InlineModifier("exclaim",  contents: "{{ value }}!")
            })
        #expect(result.replacingOccurrences(of: "\n", with: "") == "[swift]!")
    }

    @Test func chainBlueprintModifierWithBuiltIn() async throws {
        let result = try await render(
            "{{ name | shout + lowercase }}",
            data: ["name": "World"],
            blueprint: InlineBlueprint(name: "test") {
                InlineModifier("shout", contents: "{{ value | uppercase }}")
            })
        #expect(result == "world")
    }

    // MARK: Blueprint discovery (InlineBlueprintFinder)

    @Test func finderLocatesInlineBlueprint() async throws {
        let finder = InlineBlueprintFinder {
            InlineBlueprint(name: "api") {
                InlineModifier("shout", contents: "{{ value | uppercase }}")
            }
        }
        #expect(await finder.hasBlueprint(named: "api"))
        #expect(await !finder.hasBlueprint(named: "missing"))
        #expect(await finder.blueprintsAvailable == ["api"])
    }

    // MARK: Helpers

    @discardableResult
    private func render(
        _ template: String,
        data: [String: Sendable] = [:],
        blueprint: InlineBlueprint
    ) async throws -> String {
        let ws        = Workspace()
        let sandbox   = await CodeGenerationSandbox(model: ws.context.model, config: await ws.config)
        let modifiers = try await blueprint.modifiers(from: sandbox)
        return try await ws.render(string: template, data: data, modifiers: modifiers) ?? ""
    }
}
