import Testing
@testable import ModelHike

// MARK: - LogicParser unit tests

@Suite struct LogicParser_Tests {

    // MARK: Core line statements

    @Test func singleReturn() async throws {
        let logic = try await parse("return amount * 2")
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .`return`)
        #expect(await s.expression == "amount * 2")
    }

    @Test func callAndAssign() async throws {
        let logic = try await parse("""
            assign total = 0
            call audit(orderId)
            """)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .assign)
        #expect(await logic.statements[0].expression == "total = 0")
        #expect(await logic.statements[1].kind == .call)
        #expect(await logic.statements[1].expression == "audit(orderId)")
    }

    // MARK: Control flow

    @Test func ifElseBlock() async throws {
        let logic = try await parse("""
            |> IF percent <= 0
            |return amount
            |> ELSE
            |return amount * 0.9
            """)
        #expect(logic.statements.count == 2)

        let ifStmt = logic.statements[0]
        #expect(await ifStmt.kind == .`if`)
        #expect(await ifStmt.expression == "percent <= 0")
        let ifChildren = await ifStmt.children
        #expect(ifChildren.count == 1)
        #expect(await ifChildren[0].kind == .`return`)
        #expect(await ifChildren[0].expression == "amount")

        let elseStmt = logic.statements[1]
        #expect(await elseStmt.kind == .`else`)
        let elseChildren = await elseStmt.children
        #expect(elseChildren.count == 1)
        #expect(await elseChildren[0].kind == .`return`)
    }

    @Test func ifElseIf() async throws {
        let logic = try await parse("""
            |> IF score >= 90
            |return "A"
            |> ELSEIF score >= 75
            |return "B"
            |> ELSE
            |return "C"
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .`if`)
        #expect(await logic.statements[1].kind == .elseIf)
        #expect(await logic.statements[1].expression == "score >= 75")
        #expect(await logic.statements[2].kind == .`else`)
    }

    @Test func forLoop() async throws {
        let logic = try await parse("""
            assign total = 0
            |> FOR item in items
            |assign total = total + item.amount
            return total
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[1].kind == .`for`)
        let forChildren = await logic.statements[1].children
        #expect(forChildren.count == 1)
        #expect(await forChildren[0].kind == .assign)
    }

    @Test func tryCatchFinally() async throws {
        let logic = try await parse("""
            |> TRY
            |call repo.save(order)
            |> CATCH ex: DatabaseException
            |call logger.error(ex.message)
            |> FINALLY
            |call cleanup()
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .`try`)
        #expect(await logic.statements[1].kind == .`catch`)
        #expect(await logic.statements[1].expression == "ex: DatabaseException")
        #expect(await logic.statements[2].kind == .`finally`)
    }

    // MARK: Nesting

    @Test func tripleNesting() async throws {
        let logic = try await parse("""
            |> FOR item in items
            ||> IF item.active
            ||call process(item)
            """)
        #expect(logic.statements.count == 1)

        let forStmt = logic.statements[0]
        #expect(await forStmt.kind == .`for`)
        let forChildren = await forStmt.children
        #expect(forChildren.count == 1)

        let ifStmt = forChildren[0]
        #expect(await ifStmt.kind == .`if`)
        let ifChildren = await ifStmt.children
        #expect(ifChildren.count == 1)
        #expect(await ifChildren[0].kind == .call)
        #expect(await ifChildren[0].expression == "process(item)")
    }

    // MARK: Database

    @Test func dbQueryChain() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.id == orderId
            |> FIRST
            |> LET order = _
            return order
            """)
        // db> claims where/first/let as sibling children; return stands alone
        #expect(logic.statements.count == 2)
        let db = logic.statements[0]
        #expect(await db.kind == .db)
        #expect(await db.expression == "Orders")
        let dbChildren = await db.children
        #expect(dbChildren.count == 3)
        #expect(await dbChildren[0].kind == .`where`)
        #expect(await dbChildren[0].expression == "o -> o.id == orderId")
        #expect(await dbChildren[1].kind == .first)
        #expect(await dbChildren[2].kind == .`let`)
        #expect(await dbChildren[2].expression == "order = _")
        #expect(await logic.statements[1].kind == .`return`)
    }

    @Test func dbInsertUpdateDelete() async throws {
        let insert = try await parse("|> DB-INSERT Orders -> order")
        #expect(await insert.statements[0].kind == .dbInsert)

        let update = try await parse("""
            |> DB-UPDATE Orders -> o.id == id
            |> SET status = "SHIPPED"
            """)
        #expect(update.statements.count == 1)
        #expect(await update.statements[0].kind == .dbUpdate)
        // set> is claimed as sibling child of db-update>
        let updateChildren = await update.statements[0].children
        #expect(updateChildren.count == 1)
        #expect(await updateChildren[0].kind == .set)

        let delete = try await parse("|> DB-DELETE Orders -> o.id == id")
        #expect(await delete.statements[0].kind == .dbDelete)
    }

    // MARK: HTTP / API

    @Test func httpGetCall() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.example.com/users/{id}
            |> PATH
            |  id = userId
            |> AUTH bearer
            |> EXPECT 200
            |> LET user = _
            return user
            """)
        // http> claims path/auth/expect/let as sibling children; return stands alone
        #expect(logic.statements.count == 2)
        let http = logic.statements[0]
        #expect(await http.kind == .http)
        #expect(await http.expression == "GET https://api.example.com/users/{id}")
        let httpChildren = await http.children
        #expect(httpChildren.count == 4)
        #expect(await httpChildren[0].kind == .path)
        #expect(await httpChildren[1].kind == .auth)
        #expect(await httpChildren[1].expression == "bearer")
        #expect(await httpChildren[2].kind == .expect)
        #expect(await httpChildren[3].kind == .`let`)
        #expect(await logic.statements[1].kind == .`return`)
    }

    @Test func grpcCall() async throws {
        let logic = try await parse("""
            |> GRPC UserService.GetUser
            |> PAYLOAD
            |  id = userId
            |> LET user = _
            """)
        // grpc> claims payload/let as sibling children
        #expect(logic.statements.count == 1)
        let grpc = logic.statements[0]
        #expect(await grpc.kind == .grpc)
        #expect(await grpc.expression == "UserService.GetUser")
        let grpcChildren = await grpc.children
        #expect(grpcChildren.count == 2)
        #expect(await grpcChildren[0].kind == .payload)
        #expect(await grpcChildren[1].kind == .`let`)
    }

    // MARK: Edge cases

    @Test func spaceAfterPipeOnLineStatements() async throws {
        // "| keyword" (space after block-prefix pipe) is allowed for line stmts
        let logic = try await parse("""
            |> IF percent <= 0
            | return amount
            |> ELSE
            | return amount * 0.9
            """)
        #expect(logic.statements.count == 2)
        let ifChildren = await logic.statements[0].children
        #expect(ifChildren.count == 1)
        #expect(await ifChildren[0].kind == .`return`)
        #expect(await ifChildren[0].expression == "amount")
        let elseChildren = await logic.statements[1].children
        #expect(elseChildren.count == 1)
        #expect(await elseChildren[0].expression == "amount * 0.9")
    }

    @Test func spaceAfterPipeAtMultipleDepths() async throws {
        let logic = try await parse("""
            |> FOR item in items
            | |> IF item.active
            | | call process(item)
            """)
        let forChildren = await logic.statements[0].children
        let ifChildren = await forChildren[0].children
        #expect(ifChildren.count == 1)
        #expect(await ifChildren[0].kind == .call)
        #expect(await ifChildren[0].expression == "process(item)")
    }

    @Test func unknownKeywordFallback() async throws {
        let logic = try await parse("|> CUSTOM someExpression")
        #expect(logic.statements.count == 1)
        #expect(await logic.statements[0].kind == .unknown)
        #expect(await logic.statements[0].expression == "someExpression")
    }

    @Test func emptyStringReturnsNil() async {
        let logic = await CodeLogicParser.parse(dslString: "")
        #expect(logic == nil)
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic, "Expected LogicParser to return a non-nil CodeLogic")
    }
}

// MARK: - Full DSL parsing tests

@Suite struct CodeLogic_DSL_Tests {
    let ctx: LoadContext

    init() async throws {
        self.ctx = LoadContext(config: PipelineConfig())
    }

    @Test func methodLogicParsedFromDSL() async throws {
        // Setext style — opening fence is optional; body starts right after ---
        let dsl = """
            === Order Service ===
            + Order Module

            === Order Module ===

            Order
            =====
            * id     : Id
            * amount : Float

            applyDiscount(percent: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            |> IF percent <= 0
            |return amount
            |> ELSE
            |return amount * 0.9
            ~~~
            """

        let method = try await firstMethod(in: dsl)
        #expect(await method.name == "applyDiscount")
        #expect(await method.hasLogic == true)

        let logic = try await requireLogic(of: method)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .`if`)
        #expect(await logic.statements[0].expression == "percent <= 0")
        #expect(await logic.statements[1].kind == .`else`)
    }

    @Test func logicBlockTerminatesBeforeNextProperty() async throws {
        // Setext: closing fence separates logic from subsequent property
        let dsl = """
            === Order Service ===
            + Order Module

            === Order Module ===

            Order
            =====
            * id : Id
            calculateTax(rate: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            return amount * rate / 100
            ~~~
            * amount : Float
            """

        let (obj, method) = try await firstObjectAndMethod(in: dsl)

        // Both properties parsed despite logic between them
        let props = await obj.properties
        #expect(props.count == 2)
        #expect(await method.hasLogic == true)

        let logic = try await requireLogic(of: method)
        #expect(logic.statements.count == 1)
        #expect(await logic.statements[0].kind == .`return`)
    }

    @Test func methodWithoutLogicHasNilLogic() async throws {
        // Setext style is for methods with logic. Methods without logic use tilde-prefix.
        let dsl = """
            === Order Service ===
            + Order Module

            === Order Module ===

            Order
            =====
            * id : Id
            ~ getName() : String
            * name : String
            """

        let method = try await firstMethod(in: dsl)
        #expect(await method.hasLogic == false)
        #expect(await method.logic == nil)
    }

    @Test func multipleMethodsEachGetTheirOwnLogic() async throws {
        let dsl = """
            === Order Service ===
            + Order Module

            === Order Module ===

            Order
            =====
            * id     : Id
            * amount : Float

            calculateTax(rate: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            return amount * rate / 100
            ~~~

            applyDiscount(percent: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            assign discounted = amount * (1 - percent / 100)
            return discounted
            ~~~
            """

        let objects = try await allCodeObjects(in: dsl)
        let order = try #require(objects.first)
        let methods = await order.methods
        #expect(methods.count == 2)

        let tax   = methods[0]
        let disc  = methods[1]

        let taxLogic  = try await requireLogic(of: tax)
        let discLogic = try await requireLogic(of: disc)

        #expect(taxLogic.statements.count == 1)
        #expect(await taxLogic.statements[0].kind == .`return`)

        #expect(discLogic.statements.count == 2)
        #expect(await discLogic.statements[0].kind == .assign)
        #expect(await discLogic.statements[1].kind == .`return`)
    }

    // MARK: Helpers

    private func parse(_ dsl: String) async throws -> ModelSpace {
        try await ModelFileParser(with: ctx).parse(string: dsl, identifier: "test")
    }

    private func allCodeObjects(in dsl: String) async throws -> [CodeObject] {
        let space = try await parse(dsl)
        // Container→module linking requires resolveAndLinkItems; parsed modules are
        // directly accessible via modelSpace.modules before that step.
        return await space.modules.types
    }

    private func firstMethod(in dsl: String) async throws -> MethodObject {
        let objects = try await allCodeObjects(in: dsl)
        let obj = try #require(objects.first)
        let methods = await obj.methods
        return try #require(methods.first)
    }

    private func firstObjectAndMethod(in dsl: String) async throws -> (CodeObject, MethodObject) {
        let objects = try await allCodeObjects(in: dsl)
        let obj = try #require(objects.first)
        let methods = await obj.methods
        return (obj, try #require(methods.first))
    }

    private func requireLogic(of method: MethodObject) async throws -> CodeLogic {
        let logic = await method.logic
        let name  = await method.name
        return try #require(logic, "Expected method '\(name)' to have logic")
    }
}

// MARK: - Blank-line robustness tests

@Suite struct BlankLine_Parsing_Tests {
    let ctx: LoadContext
    init() async throws { self.ctx = LoadContext(config: PipelineConfig()) }

    // MARK: Empty lines between properties

    @Test func emptyLineBetweenProperties() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Product
            =======
            * id : Id

            * amount : Float
            """
        let obj = try await firstObject(in: dsl)
        let props = await obj.properties
        #expect(props.count == 2)
    }

    @Test func multipleEmptyLinesBetweenProperties() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Product
            =======
            * id : Id


            * amount : Float


            * status : String
            """
        let obj = try await firstObject(in: dsl)
        let props = await obj.properties
        #expect(props.count == 3)
    }

    // MARK: Empty lines before method

    @Test func singleEmptyLineBeforeMethod() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id : Id

            calculateTotal() : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
        #expect(await methods[0].name == "calculateTotal")
    }

    @Test func multipleEmptyLinesBeforeMethod() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id : Id



            calculateTotal() : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
    }

    @Test func emptyLinesBetweenPropertiesAndMethod() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id     : Id

            * amount : Float

            applyDiscount(percent: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            return amount * (1 - percent / 100)
            ~~~
            """
        let obj = try await firstObject(in: dsl)
        let props = await obj.properties
        #expect(props.count == 2)
        let methods = await obj.methods
        #expect(methods.count == 1)
        let logic = try await requireLogic(of: methods[0])
        #expect(logic.statements.count == 1)
        #expect(await logic.statements[0].kind == .`return`)
    }

    // MARK: Empty lines after method logic, before next property

    @Test func propertyAfterMethodWithBlankSeparator() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id : Id

            calculateTax(rate: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            return 0
            ~~~

            * amount : Float
            """
        let obj = try await firstObject(in: dsl)
        let props = await obj.properties
        #expect(props.count == 2)
        let methods = await obj.methods
        #expect(methods.count == 1)
    }

    // MARK: Multiple methods with blank lines between them

    @Test func multipleMethodsWithBlankLinesBetween() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id     : Id
            * amount : Float

            calculateTax(rate: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            return amount * rate / 100
            ~~~

            applyDiscount(percent: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            assign self.amount = amount * (1 - percent / 100)
            return this
            ~~~
            """
        let obj = try await firstObject(in: dsl)
        #expect(await obj.properties.count == 2)
        let methods = await obj.methods
        #expect(methods.count == 2)
        #expect(await (try await requireLogic(of: methods[0])).statements.count == 1)
        #expect(await (try await requireLogic(of: methods[1])).statements.count == 2)
    }

    // MARK: Tilde-prefix syntax

    @Test func tildeMethodNoLogic() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id : Id
            ~ calculateTotal() : Float
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
        #expect(await methods[0].name == "calculateTotal")
        #expect(await methods[0].logic == nil)
    }

    @Test func tildeMethodWithLogic() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id     : Id
            * amount : Float
            ~ applyDiscount(percent: Float) : Float
            ```
            return amount * (1 - percent / 100)
            ```
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
        let logic = try await requireLogic(of: methods[0])
        #expect(logic.statements.count == 1)
        #expect(await logic.statements[0].kind == .`return`)
    }

    @Test func tildeMethodWithNestedLogic() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * amount : Float
            ~ calculateTax(rate: Float) : Float
            ```
            |> IF rate <= 0
            |return 0
            |> ELSE
            |return amount * rate / 100
            ```
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
        let logic = try await requireLogic(of: methods[0])
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .if)
        #expect(await logic.statements[1].kind == .else)
    }

    @Test func tildeAndSetextMethodsMixed() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * amount : Float
            ~ calculateTax(rate: Float) : Float
            ```
            return amount * rate / 100
            ```

            applyDiscount(percent: Float) : Float
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            assign self.amount = amount * (1 - percent / 100)
            return this
            ~~~
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 2)
        #expect(await methods[0].name == "calculateTax")
        #expect(await methods[1].name == "applyDiscount")
        #expect(await (try await requireLogic(of: methods[0])).statements.count == 1)
        #expect(await (try await requireLogic(of: methods[1])).statements.count == 2)
    }

    @Test func tildeMethodBlankLineBefore() async throws {
        let dsl = """
            === Shop ===
            + Items

            === Items ===

            Order
            =====
            * id : Id

            ~ calculateTotal() : Float
            ```
            return 0
            ```
            """
        let obj = try await firstObject(in: dsl)
        let methods = await obj.methods
        #expect(methods.count == 1)
        let logic = try await requireLogic(of: methods[0])
        #expect(logic.statements.count == 1)
    }

    // MARK: Helpers

    private func allObjects(in dsl: String) async throws -> [CodeObject] {
        let space = try await ModelFileParser(with: ctx).parse(string: dsl, identifier: "test")
        return await space.modules.types
    }

    private func firstObject(in dsl: String) async throws -> CodeObject {
        let objects = try await allObjects(in: dsl)
        return try #require(objects.first)
    }

    private func requireLogic(of method: MethodObject) async throws -> CodeLogic {
        let logic = await method.logic
        let name  = await method.name
        return try #require(logic, "Expected method '\(name)' to have logic")
    }
}
