import XCTest
@testable import DiagSoup

final class TemplateSoup_String_Tests: XCTestCase {
    var arr:[DynamicTestObj] = []
    var data: [String : Any] = [:]
    
    override func setUpWithError() throws {
        self.arr = [DynamicTestObj(name: "n1", age: 1),
                    DynamicTestObj(name: "n2", age: 2),
                    DynamicTestObj(name: "", age: 3)]

        self.data = ["list":arr, "var1" : true, "var2": false, "varstr": "sfsf"]
    }

    override func tearDownWithError() throws {
        self.arr = []
        self.data = [:]
    }

    func testSimplePrint() throws {
        // Given
        let input = "{{ var1 }}"
        
        let expectedOutput = "true"

        // When
        let ws = Workspace();
        let result = ws.render(string: input, data: data)

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testExpressionPrint() throws {
        // Given
        let input = "{{ (var1 and var2) and var2}}"
        
        let expectedOutput = "false"

        // When
        let ws = Workspace();
        let result = ws.render(string: input, data: data)

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testComplexTemplateWuthMacroFunctions() throws {
        // Given
        let input = """
            : set submodule_folder_name = "some-name"| lowercase + kebabcase //comment
            : func fn1(param1) //comment
            : set testname2 //comment
            GG_Tr{{submodule_folder_name}} ={{ call fn2(param1 : "Ssf") }}=
            : endset //comment
            {{testname2}}
            : endfunc
            :
            : func fn2(param1)
             : set testname3
            hi
            : endset
            tyty
            : endfunc

            : call fn1(param1 : "Ssf")
            : for test in list
            jekii
            : set-obj-attrib test.name = testname2| lowercase + kebabcase

            : if test.name
            inside if {{test.name}}
            : else
            inside else {{test.name}}
            : endif
            : endfor

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

        // When
        let ws = Workspace();
        let result = ws.render(string: input, data: data)!

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testSimpleNestedLoops() throws {
        // Given
        let input = """
            : for i in list
            jekii
            fsdf
            : endfor

            : for yi in list
            12121
            : if var1
            a
            : for jj in list
            a
            : endfor
            : endif
            : for q in list
            a
            : endfor
            323232
            323232323232
            323232
            : endfor

            : if var1
            a
            : else if var2
            b
            : for i in list
            jekii
            fsdf
            : endfor
            : else
            c
            : endif

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

        // When
        let ws = Workspace();
        let result = ws.render(string: input, data: data)!

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    struct DynamicTestObj : DynamicMemberLookup, HasAttributes {
        public var attribs = Attributes()
        
        subscript(member: String) -> Any {
            return self.attribs["name"] as Any
        }
        
        public init(name: String, age: Int) {
            self.attribs["name"] = name
            self.attribs["age"] = name
        }
    }
}
