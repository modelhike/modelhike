import Testing
@testable import ModelHike

// MARK: - Control-flow statement tests
//
// Covers: if / elseif / else · for · while · try/catch/finally · switch/case/default
//         compiler directives (#if/#else/#endif) · nested control flow

@Suite("Control Flow") struct ControlFlow_Tests {

    // MARK: if / elseif / else

    @Test func ifOnly() async throws {
        let logic = try await parse("""
            |> IF x > 0
            |return x
            """)
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .`if`)
        #expect(await s.expression == "x > 0")
        let ch = await s.children
        #expect(ch.count == 1)
        #expect(await ch[0].kind == .`return`)
        #expect(await ch[0].expression == "x")

        guard case .ifStmt(let node) = await s.node else { Issue.record("Expected .ifStmt"); return }
        #expect(node.condition == "x > 0")
    }

    @Test func ifElse() async throws {
        let logic = try await parse("""
            |> IF flag
            |return true
            |> ELSE
            |return false
            """)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .`if`)
        #expect(await logic.statements[1].kind == .`else`)
        let elseChildren = await logic.statements[1].children
        #expect(await elseChildren[0].kind == .`return`)
        #expect(await elseChildren[0].expression == "false")
    }

    @Test func ifElseIfElse() async throws {
        let logic = try await parse("""
            |> IF score >= 90
            |return "A"
            |> ELSEIF score >= 75
            |return "B"
            |> ELSEIF score >= 60
            |return "C"
            |> ELSE
            |return "F"
            """)
        #expect(logic.statements.count == 4)
        #expect(await logic.statements[0].kind == .`if`)
        #expect(await logic.statements[1].kind == .elseIf)
        #expect(await logic.statements[1].expression == "score >= 75")
        #expect(await logic.statements[2].kind == .elseIf)
        #expect(await logic.statements[2].expression == "score >= 60")
        #expect(await logic.statements[3].kind == .`else`)

        guard case .elseIfStmt(let node) = await logic.statements[1].node else {
            Issue.record("Expected .elseIfStmt"); return
        }
        #expect(node.condition == "score >= 75")
    }

    // MARK: for

    @Test func forLoop() async throws {
        let logic = try await parse("""
            |> FOR item in items
            |call process(item)
            """)
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .`for`)
        let ch = await s.children
        #expect(ch.count == 1)
        #expect(await ch[0].kind == .call)

        guard case .forLoop(let node) = await s.node else { Issue.record("Expected .forLoop"); return }
        #expect(node.item == "item")
        #expect(node.collection == "items")
    }

    @Test func forWithMultipleBodyStatements() async throws {
        let logic = try await parse("""
            |> FOR order in orders
            |assign tax = order.amount * 0.1
            |assign total = order.amount + tax
            |call repo.save(order)
            """)
        let ch = await logic.statements[0].children
        #expect(ch.count == 3)
        #expect(await ch[0].kind == .assign)
        #expect(await ch[1].kind == .assign)
        #expect(await ch[2].kind == .call)
    }

    // MARK: while

    @Test func whileLoop() async throws {
        let logic = try await parse("""
            |> WHILE queue.isNotEmpty
            |assign item = queue.dequeue()
            |call process(item)
            """)
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .`while`)
        guard case .whileLoop(let node) = await s.node else { Issue.record("Expected .whileLoop"); return }
        #expect(node.condition == "queue.isNotEmpty")
        #expect((await s.children).count == 2)
    }

    // MARK: try / catch / finally

    @Test func tryCatch() async throws {
        let logic = try await parse("""
            |> TRY
            |call repo.save(entity)
            |> CATCH ex: IOException
            |call logger.error(ex)
            """)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .`try`)
        let catchStmt = logic.statements[1]
        #expect(await catchStmt.kind == .`catch`)
        #expect(await catchStmt.expression == "ex: IOException")

        guard case .catchClause(let node) = await catchStmt.node else {
            Issue.record("Expected .catchClause"); return
        }
        #expect(node.variable == "ex")
        #expect(node.type == "IOException")
    }

    @Test func tryCatchFinally() async throws {
        let logic = try await parse("""
            |> TRY
            |call repo.save(entity)
            |> CATCH ex: DatabaseException
            |call logger.error(ex.message)
            |> FINALLY
            |call cleanup()
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .`try`)
        #expect(await logic.statements[1].kind == .`catch`)
        #expect(await logic.statements[2].kind == .`finally`)
        let finallyChildren = await logic.statements[2].children
        #expect(await finallyChildren[0].kind == .call)
    }

    @Test func catchWithNoType() async throws {
        let logic = try await parse("""
            |> TRY
            |call risky()
            |> CATCH err:
            |return nil
            """)
        let catchStmt = logic.statements[1]
        guard case .catchClause(let node) = await catchStmt.node else {
            Issue.record("Expected .catchClause"); return
        }
        #expect(node.variable == "err")
        #expect(node.type == nil)
    }

    // MARK: switch / case / default

    @Test func switchCaseDefault() async throws {
        let logic = try await parse("""
            |> SWITCH status
            |> CASE "active"
            |return true
            |> CASE "inactive"
            |return false
            |> DEFAULT
            |return nil
            """)
        #expect(logic.statements.count == 4)
        #expect(await logic.statements[0].kind == .`switch`)
        guard case .switchStmt(let node) = await logic.statements[0].node else {
            Issue.record("Expected .switchStmt"); return
        }
        #expect(node.subject == "status")

        #expect(await logic.statements[1].kind == .`case`)
        guard case .caseClause(let caseNode) = await logic.statements[1].node else {
            Issue.record("Expected .caseClause"); return
        }
        #expect(caseNode.value == "\"active\"")

        #expect(await logic.statements[3].kind == .`default`)
    }

    // MARK: Compiler directives

    @Test func compilerDirectives() async throws {
        let logic = try await parse("""
            |> #IF DEBUG
            |call logger.verbose(msg)
            |> #ELSE
            |call logger.info(msg)
            |> #ENDIF
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .compilerIf)
        #expect(await logic.statements[1].kind == .compilerElse)
        #expect(await logic.statements[2].kind == .compilerEndIf)

        guard case .compilerDirectiveIf(let node) = await logic.statements[0].node else {
            Issue.record("Expected .compilerDirectiveIf"); return
        }
        #expect(node.symbol == "DEBUG")
    }

    // MARK: Nested control flow

    @Test func nestedForInsideIf() async throws {
        let logic = try await parse("""
            |> IF items.isNotEmpty
            ||> FOR item in items
            ||call process(item)
            """)
        #expect(logic.statements.count == 1)
        #expect(await logic.statements[0].kind == .`if`)
        let ifChildren = await logic.statements[0].children
        #expect(ifChildren.count == 1)
        #expect(await ifChildren[0].kind == .`for`)
        let forChildren = await ifChildren[0].children
        #expect(await forChildren[0].kind == .call)
    }

    @Test func nestedIfInsideFor() async throws {
        let logic = try await parse("""
            |> FOR item in items
            ||> IF item.active
            ||call process(item)
            ||> ELSE
            ||call skip(item)
            """)
        let forChildren = await logic.statements[0].children
        #expect(forChildren.count == 2)
        #expect(await forChildren[0].kind == .`if`)
        #expect(await forChildren[1].kind == .`else`)
    }

    @Test func tripleDepthNesting() async throws {
        let logic = try await parse("""
            |> FOR group in groups
            ||> FOR item in group.items
            |||> IF item.active
            |||call process(item)
            """)
        let forChildren   = await logic.statements[0].children
        let innerFor      = forChildren[0]
        let innerForCh    = await innerFor.children
        let ifStmt        = innerForCh[0]
        let ifChildren    = await ifStmt.children
        #expect(await ifChildren[0].kind == .call)
        #expect(await ifChildren[0].expression == "process(item)")
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}
