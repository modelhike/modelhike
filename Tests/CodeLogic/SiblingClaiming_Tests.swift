import Testing
@testable import ModelHike

// MARK: - Sibling-claiming boundary & interaction tests
//
// Verifies that block kinds claim exactly the right siblings and stop at the right boundary.

@Suite("Sibling Claiming") struct SiblingClaiming_Tests {

    // MARK: db> stops at first non-db-child kind

    @Test func dbClaimingStopsAtReturn() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.active
            |> LET orders = _
            return orders
            """)
        #expect(logic.statements.count == 2)
        #expect(await logic.statements[0].kind == .db)
        #expect(await logic.statements[1].kind == .`return`)
        let dbChildren = await logic.statements[0].children
        #expect(dbChildren.count == 2)   // where + let
    }

    @Test func dbClaimingStopsAtAssign() async throws {
        let logic = try await parse("""
            |> DB Users
            |> TO-LIST
            |> LET users = _
            assign count = users.count
            return count
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .db)
        #expect(await logic.statements[1].kind == .assign)
        #expect(await logic.statements[2].kind == .`return`)
    }

    // MARK: Two db> blocks in sequence

    @Test func twoDbBlocksInSequence() async throws {
        let logic = try await parse("""
            |> DB Orders
            |> WHERE o -> o.id == orderId
            |> FIRST
            |> LET order = _
            |> DB Users
            |> WHERE u -> u.id == order.userId
            |> FIRST
            |> LET user = _
            return user
            """)
        // Each db> should claim its own siblings independently
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .db)
        #expect(await logic.statements[1].kind == .db)
        #expect(await logic.statements[2].kind == .`return`)

        let db1Children = await logic.statements[0].children
        #expect(db1Children.count == 3)  // where + first + let

        let db2Children = await logic.statements[1].children
        #expect(db2Children.count == 3)  // where + first + let
    }

    // MARK: http> and db> in same method

    @Test func dbThenHttp() async throws {
        let logic = try await parse("""
            |> DB Users
            |> WHERE u -> u.id == userId
            |> FIRST
            |> LET user = _
            |> HTTP POST https://notify.example.com/send
            |> BODY
            |  email = user.email
            |  message = "Hello"
            |> EXPECT 200
            |> LET _ = _
            return user
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .db)
        #expect(await logic.statements[1].kind == .http)
        #expect(await logic.statements[2].kind == .`return`)

        let dbChildren  = await logic.statements[0].children
        let httpChildren = await logic.statements[1].children
        #expect(dbChildren.count == 3)    // where + first + let
        #expect(httpChildren.count == 3)  // body + expect + let
    }

    // MARK: db> inside control flow

    @Test func dbInsideIfBlock() async throws {
        let logic = try await parse("""
            |> IF userId != nil
            ||> DB Users
            ||> WHERE u -> u.id == userId
            ||> FIRST
            ||> LET user = _
            |return user
            |> ELSE
            |return nil
            """)
        #expect(logic.statements.count == 2)
        let ifChildren = await logic.statements[0].children
        // The first child of IF is the db block; the second is the return
        #expect(ifChildren.count == 2)
        #expect(await ifChildren[0].kind == .db)
        #expect(await ifChildren[1].kind == .`return`)

        let dbChildren = await ifChildren[0].children
        #expect(dbChildren.count == 3) // where + first + let
    }

    // MARK: db-update> stops after all set> siblings

    @Test func dbUpdateClaimsAllSetSiblings() async throws {
        let logic = try await parse("""
            |> DB-UPDATE Orders -> o.id == orderId
            |> SET status = "SHIPPED"
            |> SET shippedAt = now()
            |> SET trackingId = tracking
            return "ok"
            """)
        #expect(logic.statements.count == 2)
        let updateChildren = await logic.statements[0].children
        #expect(updateChildren.count == 3)
        #expect(await logic.statements[1].kind == .`return`)
    }

    // MARK: grpc> stops at non-grpc-child kind

    @Test func grpcClaimingStopsAtCall() async throws {
        let logic = try await parse("""
            |> GRPC OrderService.PlaceOrder
            |> PAYLOAD
            |  items = cart.items
            |> LET order = _
            call auditLog(order)
            return order
            """)
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .grpc)
        #expect(await logic.statements[1].kind == .call)
        #expect(await logic.statements[2].kind == .`return`)
        let grpcChildren = await logic.statements[0].children
        #expect(grpcChildren.count == 2) // payload + let
    }

    // MARK: db-proc-call> with params and let

    @Test func dbProcCallClaimsParamsAndLet() async throws {
        let logic = try await parse("""
            |> DB-PROC-CALL dbo.CalcTotals
            |> PARAMS
            |  month = currentMonth
            |> LET totals = _
            return totals
            """)
        #expect(logic.statements.count == 2)
        let procChildren = await logic.statements[0].children
        #expect(procChildren.count == 2)   // params + let
        #expect(await procChildren[0].kind == .params)
        #expect(await procChildren[1].kind == .`let`)
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}
