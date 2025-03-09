import XCTest
@testable import ModelHike

final class ExpressionParsing_Tests: XCTestCase {
    var arr:[DynamicTestObj] = []
    var data2: StringDictionary = [:]
    var context: Context = Context()
    
    override func setUpWithError() throws {
        self.arr = [DynamicTestObj(name: "n1", age: 1),
                    DynamicTestObj(name: "n2", age: 2),
                    DynamicTestObj(name: "", age: 3)]

        self.data2 = ["list":arr, "var1" : true, "var2": false]

        self.context = Context(data: data2)
        context.symbols.template.add(infixOperators : DefaultOperatorsLibrary.infixOperators)

    }

    override func tearDownWithError() throws {
        self.arr = []
        self.data2 = [:]
    }

    func testComplexExpression1() throws {
        // Given
        let expn = """
        (var1 or var2 and var1 and var1 and var1) or (var2) and (var2 and var1)
        """
        
        let expectedOutput = false

        // When
        var parser = RegularExpressionEvaluator()
        let result = try parser.evaluate(expression: expn, lineNo: 1, with: context) as! Bool

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testComplexExpression2() throws {
        // Given
        let expn = """
            (var1 and var2 and var1 and var1 and var1) or (var2) and (var2 and var1)
            """
        
        let expectedOutput = false

        // When
        var parser = RegularExpressionEvaluator()
        let result = try parser.evaluate(expression: expn, lineNo: 1, with: context)  as! Bool

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testComplexExpression3() throws {
        // Given
        let expn = """
            var1 and (var2 or var2) and var2 or var1
            """
        
        let expectedOutput = false

        // When
        var parser = RegularExpressionEvaluator()
        let result = try parser.evaluate(expression: expn, lineNo: 1, with: context)  as! Bool

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testComplexExpression4() throws {
        // Given
        let expn = """
            var1 and (var2 or var1 and var1) and (var1 and var1) or var2
            """
        
        let expectedOutput = true

        // When
        var parser = RegularExpressionEvaluator()
        let result = try parser.evaluate(expression: expn, lineNo: 1, with: context)  as! Bool

        // Then
        XCTAssertEqual(result, expectedOutput)
    }
    
    func testInvalidExpressionError() throws {
        // Given
        let expn = "(var1 and var2) hu var2"

        // When & Then
        var parser = RegularExpressionEvaluator()

        XCTAssertThrowsError(try parser.evaluate(expression: expn, lineNo: 1, with: context)) { error in
            // Verify the type and content of the error if necessary
            XCTAssertEqual(error as? TemplateSoup_ParsingError, TemplateSoup_ParsingError.invalidExpression(1, expn))
        }
        
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
