import Testing
@testable import ModelHike

// MARK: - Database statement tests
//
// Covers: db (query chain) · db-insert · db-update · db-delete
//         group-by · aggregate · db-proc-call · db-raw

@Suite("Database Statements") struct Database_Tests {

    // MARK: db query chain — sibling children

    @Test func dbWithWhere() async throws {
        let logic = try await parse("""
            |> DB Users
            |> WHERE u -> u.active == true
            |> LET users = _
            """)
        #expect(logic.statements.count == 1)
        let db = logic.statements[0]
        #expect(await db.kind == .db)
        #expect(await db.expression == "Users")
        let children = await db.children
        #expect(children.count == 2)
        #expect(await children[0].kind == .`where`)
        #expect(await children[1].kind == .`let`)

        guard case .db(let node) = await db.node else { Issue.record("Expected .db"); return }
        #expect(node.entity == "Users")
        #expect(node.where_?.lambda == "u -> u.active == true")
        #expect(node.letBinding?.name == "users")
    }

    @Test func dbWithMultipleIncludes() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> INCLUDE items
            |> INCLUDE customer
            |> INCLUDE shipping
            |> LET orders = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.includes.count == 3)
        #expect(node.includes[0].relation == "items")
        #expect(node.includes[1].relation == "customer")
        #expect(node.includes[2].relation == "shipping")
        #expect(node.letBinding?.name == "orders")
    }

    @Test func dbOrderByAsc() async throws {
        let logic = try await parse("""
            |> DB Products
            |> ORDER-BY name asc
            |> LET products = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.orderBy?.expression == "name")
        #expect(node.orderBy?.direction == .asc)
    }

    @Test func dbOrderByDesc() async throws {
        let logic = try await parse("""
            |> DB Events
            |> ORDER-BY createdAt desc
            |> LET events = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.orderBy?.direction == .desc)
    }

    @Test func dbSkipTake() async throws {
        let logic = try await parse("""
            |> DB Products
            |> SKIP 20
            |> TAKE 10
            |> LET page = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.skip?.count == "20")
        #expect(node.take?.count == "10")
    }

    @Test func dbToList() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.userId == userId
            |> TO-LIST
            |> LET orders = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.materialize == .toList)
        #expect(node.where_?.lambda == "o -> o.userId == userId")
    }

    @Test func dbFirst() async throws {
        let logic = try await parse("""
            |> DB Users
            |> WHERE u -> u.email == email
            |> FIRST
            |> LET user = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.materialize == .first)
    }

    @Test func dbSingle() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.id == orderId
            |> SINGLE
            |> LET order = _
            """)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.materialize == .single)
    }

    @Test func dbFullChain() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.status == "active"
            |> INCLUDE items
            |> INCLUDE customer
            |> ORDER-BY createdAt desc
            |> SKIP 0
            |> TAKE 25
            |> TO-LIST
            |> LET orders = _
            return orders
            """)
        #expect(logic.statements.count == 2)
        guard case .db(let node) = await logic.statements[0].node else {
            Issue.record("Expected .db"); return
        }
        #expect(node.entity == "Orders")
        #expect(node.where_?.lambda == "o -> o.status == \"active\"")
        #expect(node.includes.count == 2)
        #expect(node.orderBy?.direction == .desc)
        #expect(node.skip?.count == "0")
        #expect(node.take?.count == "25")
        #expect(node.materialize == .toList)
        #expect(node.letBinding?.name == "orders")
        #expect(await logic.statements[1].kind == .`return`)
    }

    // MARK: db-insert

    @Test func dbInsert() async throws {
        let logic = try await parse("|> DB-INSERT Orders -> order")
        let s = logic.statements[0]
        #expect(await s.kind == .dbInsert)
        guard case .dbInsert(let node) = await s.node else { Issue.record("Expected .dbInsert"); return }
        #expect(node.entity == "Orders")
        #expect(node.source == "order")
    }

    // MARK: db-update

    @Test func dbUpdateWithSetFields() async throws {
        let logic = try await parse("""
            |> DB-UPDATE Orders -> o.id == orderId
            |> SET status = "SHIPPED"
            |> SET shippedAt = now
            """)
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .dbUpdate)
        let children = await s.children
        #expect(children.count == 2)
        #expect(await children[0].kind == .set)
        #expect(await children[1].kind == .set)

        guard case .dbUpdate(let node) = await s.node else { Issue.record("Expected .dbUpdate"); return }
        #expect(node.entity == "Orders")
        #expect(node.predicate == "o.id == orderId")
        #expect(node.fields.count == 2)
        #expect(node.fields[0].key == "status")
        #expect(node.fields[0].value == "\"SHIPPED\"")
        #expect(node.fields[1].key == "shippedAt")
    }

    // MARK: db-delete

    @Test func dbDelete() async throws {
        let logic = try await parse("|> DB-DELETE Sessions -> s.userId == userId")
        let s = logic.statements[0]
        #expect(await s.kind == .dbDelete)
        guard case .dbDelete(let node) = await s.node else { Issue.record("Expected .dbDelete"); return }
        #expect(node.entity == "Sessions")
        #expect(node.predicate == "s.userId == userId")
    }

    // MARK: group-by / aggregate

    @Test func groupByAggregate() async throws {
        let logic = try await parse("""
            |> GROUP-BY o -> o.status
            |> AGGREGATE count()
            """)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .groupBy)
        #expect(await logic.statements[1].kind == .aggregate)

        guard case .groupBy(let gbNode) = await logic.statements[0].node else {
            Issue.record("Expected .groupBy"); return
        }
        #expect(gbNode.lambda == "o -> o.status")

        guard case .aggregate(let aggNode) = await logic.statements[1].node else {
            Issue.record("Expected .aggregate"); return
        }
        #expect(aggNode.function == "count()")
    }

    // MARK: db-proc-call

    @Test func dbProcCall() async throws {
        let logic = try await parse("""
            |> DB-PROC-CALL dbo.GetOrderSummary
            |> PARAMS
            |  userId = currentUser.id
            |  startDate = range.start
            |> LET result = _
            """)
        #expect(logic.statements.count == 1)
        let s = logic.statements[0]
        #expect(await s.kind == .dbProcCall)
        let children = await s.children
        #expect(children.count == 2)
        #expect(await children[0].kind == .params)
        #expect(await children[1].kind == .`let`)

        guard case .dbProcCall(let node) = await s.node else { Issue.record("Expected .dbProcCall"); return }
        #expect(node.procedure == "dbo.GetOrderSummary")
        #expect(node.params.count == 2)
        #expect(node.params[0].key == "userId")
        #expect(node.params[1].key == "startDate")
        #expect(node.letBinding?.name == "result")
    }

    // MARK: db-raw

    @Test func dbRawWithSqlAndParams() async throws {
        // SQL keywords (SELECT, WHERE) collide with Midlang keywords, so use a stored-proc call
        // that avoids those tokens while still testing the sql> block plumbing.
        let logic = try await parse("""
            |> DB-RAW postgres
            |> PARAMS
            |  id = orderId
            |> SQL
            |  EXEC GetOrderById :id
            |> LET result = _
            """)
        // db-raw> claims params/sql; let is a separate statement (DbRawNode has no letBinding).
        #expect(logic.statements.count == 2)
        let s = logic.statements[0]
        #expect(await s.kind == .dbRaw)
        #expect(await logic.statements[1].kind == .`let`)

        guard case .dbRaw(let node) = await s.node else { Issue.record("Expected .dbRaw"); return }
        #expect(node.source == "postgres")
        #expect(node.params.count == 1)
        #expect(node.params[0].key == "id")
        #expect(node.sqlLines.count == 1)
        #expect(node.sqlLines[0].contains("GetOrderById"))
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}
