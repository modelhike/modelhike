import Testing
@testable import ModelHike

@Suite struct ExpressionParsing_Tests {
    let context: LoadContext
    let pInfo: ParsedInfo
    let evaluator = RegularExpressionEvaluator()

    init() async throws {
        let obj1 = await DynamicTestObj(name: "n1", age: 1)
        let obj2 = await DynamicTestObj(name: "n2", age: 2)
        let obj3 = await DynamicTestObj(name: "", age: 3)
        let arr: [DynamicTestObj] = [obj1, obj2, obj3]

        let ctx = LoadContext(config: PipelineConfig())
        await ctx.symbols.addTemplate(infixOperators: DefaultOperatorsLibrary.infixOperators)
        await ctx.replace(variables: ["list": arr, "var1": true, "var2": false])
        self.context = ctx
        self.pInfo = await ParsedInfo.dummy(line: "", identifier: "test", loadCtx: ctx)
    }

    @Test func complexExpression1() async throws {
        let expn = "(var1 or var2 and var1 and var1 and var1) or (var2) and (var2 and var1)"
        let result = try await evaluator.evaluate(expression: expn, pInfo: pInfo) as! Bool
        #expect(result == false)
    }

    @Test func complexExpression2() async throws {
        let expn = "(var1 and var2 and var1 and var1 and var1) or (var2) and (var2 and var1)"
        let result = try await evaluator.evaluate(expression: expn, pInfo: pInfo) as! Bool
        #expect(result == false)
    }

    @Test func complexExpression3() async throws {
        let expn = "var1 and (var2 or var2) and var2 or var1"
        let result = try await evaluator.evaluate(expression: expn, pInfo: pInfo) as! Bool
        #expect(result == false)
    }

    @Test func complexExpression4() async throws {
        let expn = "var1 and (var2 or var1 and var1) and (var1 and var1) or var2"
        let result = try await evaluator.evaluate(expression: expn, pInfo: pInfo) as! Bool
        #expect(result == true)
    }

    @Test func invalidExpressionError() async throws {
        let expn = "(var1 and var2) hu var2"
        await #expect(throws: TemplateSoup_ParsingError.self) {
            try await evaluator.evaluate(expression: expn, pInfo: pInfo)
        }
    }

    actor DynamicTestObj: DynamicMemberLookup, HasAttributes {
        nonisolated let attribs = Attributes()

        func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
            return await attribs[propname]
        }

        init(name: String, age: Int) async {
            await attribs.set("name", value: name)
            await attribs.set("age", value: age)
        }
    }
}
