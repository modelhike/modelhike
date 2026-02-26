import Testing
@testable import ModelHike

// MARK: - Core imperative & functional statement tests
//
// Covers: call · assign · return · expr · raw
//         let · match/when/endmatch
//         pipe · filter · select · map · reduce

@Suite("Core & Functional Statements") struct CoreStmts_Tests {

    // MARK: call

    @Test func callStatement() async throws {
        let logic = try await parse("call repo.save(order)")
        let s = logic.statements[0]
        #expect(await s.kind == .call)
        #expect(await s.expression == "repo.save(order)")
        guard case .call(let node) = await s.node else { Issue.record("Expected .call"); return }
        #expect(node.callExpression == "repo.save(order)")
    }

    // MARK: assign

    @Test func assignStatement() async throws {
        let logic = try await parse("assign total = price * qty")
        let s = logic.statements[0]
        #expect(await s.kind == .assign)
        guard case .assign(let node) = await s.node else { Issue.record("Expected .assign"); return }
        #expect(node.lhs == "total")
        #expect(node.rhs == "price * qty")
    }

    @Test func assignFieldPair() async throws {
        let logic = try await parse("assign x = 0")
        guard case .assign(let node) = await logic.statements[0].node else {
            Issue.record("Expected .assign"); return
        }
        let pair = node.asFieldPair
        #expect(pair.key == "x")
        #expect(pair.value == "0")
    }

    // MARK: return

    @Test func returnWithExpression() async throws {
        let logic = try await parse("return amount * 1.1")
        let s = logic.statements[0]
        #expect(await s.kind == .`return`)
        guard case .returnStmt(let node) = await s.node else { Issue.record("Expected .returnStmt"); return }
        #expect(node.expression == "amount * 1.1")
    }

    @Test func returnVoid() async throws {
        let logic = try await parse("return")
        guard case .returnStmt(let node) = await logic.statements[0].node else {
            Issue.record("Expected .returnStmt"); return
        }
        #expect(node.expression == "")
    }

    // MARK: expr

    @Test func exprStatement() async throws {
        let logic = try await parse("expr list.sort()")
        let s = logic.statements[0]
        #expect(await s.kind == .expr)
        guard case .expr(let node) = await s.node else { Issue.record("Expected .expr"); return }
        #expect(node.expression == "list.sort()")
    }

    // MARK: raw

    @Test func rawSingleLine() async throws {
        let logic = try await parse("|> RAW someRawContent")
        let s = logic.statements[0]
        #expect(await s.kind == .raw)
        guard case .raw(let node) = await s.node else { Issue.record("Expected .raw"); return }
        #expect(node.content == "someRawContent")
        #expect(node.lines.isEmpty)
    }

    @Test func rawMultiLine() async throws {
        let logic = try await parse("""
            |> RAW
            |line one
            |line two
            |line three
            """)
        guard case .raw(let node) = await logic.statements[0].node else {
            Issue.record("Expected .raw"); return
        }
        #expect(node.lines == ["line one", "line two", "line three"])
    }

    // MARK: let

    @Test func letBinding() async throws {
        let logic = try await parse("let result = _")
        let s = logic.statements[0]
        #expect(await s.kind == .`let`)
        guard case .letBinding(let node) = await s.node else { Issue.record("Expected .letBinding"); return }
        #expect(node.name == "result")
    }

    @Test func letWithoutAssign() async throws {
        let logic = try await parse("let items")
        guard case .letBinding(let node) = await logic.statements[0].node else {
            Issue.record("Expected .letBinding"); return
        }
        #expect(node.name == "items")
    }

    // MARK: match / when / endmatch

    @Test func matchBlock() async throws {
        let logic = try await parse("""
            |> MATCH result
            |> WHEN Ok(value)
            |return value
            |> WHEN Err(e)
            |call logger.error(e)
            |> ENDMATCH
            """)
        #expect(logic.statements.count == 4)
        #expect(await logic.statements[0].kind == .match)
        #expect(await logic.statements[1].kind == .when)
        #expect(await logic.statements[2].kind == .when)
        #expect(await logic.statements[3].kind == .endMatch)

        guard case .match(let matchNode) = await logic.statements[0].node else {
            Issue.record("Expected .match"); return
        }
        #expect(matchNode.expression == "result")

        guard case .when(let whenNode) = await logic.statements[1].node else {
            Issue.record("Expected .when"); return
        }
        #expect(whenNode.pattern == "Ok(value)")
    }

    // MARK: Functional pipeline

    @Test func pipeFilterMapReduce() async throws {
        let logic = try await parse("""
            |> PIPE orders
            |> FILTER o -> o.active
            |> MAP o -> o.total
            |> REDUCE sum(0)
            return result
            """)
        #expect(logic.statements.count == 5)
        #expect(await logic.statements[0].kind == .pipe)
        #expect(await logic.statements[1].kind == .filter)
        #expect(await logic.statements[2].kind == .map)
        #expect(await logic.statements[3].kind == .reduce)
        #expect(await logic.statements[4].kind == .`return`)

        guard case .pipe(let pipeNode) = await logic.statements[0].node else {
            Issue.record("Expected .pipe"); return
        }
        #expect(pipeNode.source == "orders")

        guard case .filter(let filterNode) = await logic.statements[1].node else {
            Issue.record("Expected .filter"); return
        }
        #expect(filterNode.lambda == "o -> o.active")
    }

    @Test func selectStatement() async throws {
        let logic = try await parse("|> SELECT item -> item.name")
        guard case .select(let node) = await logic.statements[0].node else {
            Issue.record("Expected .select"); return
        }
        #expect(node.lambda == "item -> item.name")
    }

    // MARK: Multiple statements mixed

    @Test func sequenceOfCoreStatements() async throws {
        let logic = try await parse("""
            assign count = 0
            call validate(input)
            assign result = compute(input)
            return result
            """)
        #expect(logic.statements.count == 4)
        #expect(await logic.statements[0].kind == .assign)
        #expect(await logic.statements[1].kind == .call)
        #expect(await logic.statements[2].kind == .assign)
        #expect(await logic.statements[3].kind == .`return`)
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}

// MARK: - AssignNode helper

private extension CodeLogicStmt.AssignNode {
    var asFieldPair: CodeLogicStmt.AssignNode.FieldPair {
        .init(key: lhs, value: rhs)
    }
}
