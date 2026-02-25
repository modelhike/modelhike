import Testing
@testable import ModelHike

@Suite struct TemplateSoup_String_Tests {
    let arr: [DynamicTestObj]
    let data: [String: Sendable]

    init() async throws {
        let obj1 = await DynamicTestObj(name: "n1", age: 1)
        let obj2 = await DynamicTestObj(name: "n2", age: 2)
        let obj3 = await DynamicTestObj(name: "", age: 3)
        let tempArr = [obj1, obj2, obj3]
        self.arr = tempArr
        self.data = ["list": tempArr, "var1": true, "var2": false, "varstr": "sfsf"]
    }

    @Test func simplePrint() async throws {
        let input = "{{ var1 }}"
        let ws = Workspace()
        let result = try await ws.render(string: input, data: data)
        #expect(result == "true")
    }

    @Test func expressionPrint() async throws {
        let input = "{{ (var1 and var2) and var2}}"
        let ws = Workspace()
        let result = try await ws.render(string: input, data: data)
        #expect(result == "false")
    }

    @Test func complexTemplateWithMacroFunctions() async throws {
        let input = """
            : set submodule_folder_name = "some-name"| lowercase + kebabcase //comment
            : func fn1(param1) //comment
            : set-str testname2 //comment
            GG_Tr{{submodule_folder_name}} ={{ call fn2(param1 : "Ssf") }}=
            : end-set //comment
            {{testname2}}
            : end-func
            :
            : func fn2(param1)
             : set-str testname3
            hi
            : end-set
            tyty
            : end-func

            : call fn1(param1 : "Ssf")
            : for test in list
            jekii
            : set test.name = testname2| lowercase + kebabcase

            : if test.name
            inside if {{test.name}}
            : else
            inside else {{test.name}}
            : end-if
            : end-for

            """

        let expectedOutput = """
                GG_Trsome-name tyty
                jekii
                inside if gg-trsome-name-tyty
                jekii
                inside if gg-trsome-name-tyty
                jekii
                inside if gg-trsome-name-tyty
                """

        let ws = Workspace()
        let result = try await ws.render(string: input, data: data)
        #expect(result == expectedOutput)
    }

    @Test func simpleNestedLoops() async throws {
        let input = """
            : for i in list
            jekii
            fsdf
            : end-for

            : for yi in list
            12121
            : if var1
            a
            : for jj in list
            a
            : end-for
            : end-if
            : for q in list
            a
            : end-for
            323232
            323232323232
            323232
            : end-for

            : if var1
            a
            : else-if var2
            b
            : for i in list
            jekii
            fsdf
            : end-for
            : else
            c
            : end-if

            """

        let expectedOutput = """
                jekii
                fsdf
                jekii
                fsdf
                jekii
                fsdf
                12121
                a
                a
                a
                a
                a
                a
                a
                323232
                323232323232
                323232
                12121
                a
                a
                a
                a
                a
                a
                a
                323232
                323232323232
                323232
                12121
                a
                a
                a
                a
                a
                a
                a
                323232
                323232323232
                323232
                a
                """

        let ws = Workspace()
        let result = try await ws.render(string: input, data: data)
        #expect(result == expectedOutput)
    }

    actor DynamicTestObj: HasAttributes {
        nonisolated let attribs = Attributes()

        init(name: String, age: Int) async {
            await attribs.set("name", value: name)
            await attribs.set("age", value: age)
        }
    }
}
