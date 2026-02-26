import Testing
@testable import ModelHike

// MARK: - gRPC statement tests
//
// Covers: grpc · payload · metadata — sibling claiming & typed node fields

@Suite("gRPC Statements") struct GRPC_Tests {

    @Test func grpcWithPayload() async throws {
        let logic = try await parse("""
            |> GRPC UserService.GetUser
            |> PAYLOAD
            |  id = userId
            |> LET user = _
            return user
            """)
        #expect(logic.statements.count == 2)
        let grpc = logic.statements[0]
        #expect(await grpc.kind == .grpc)
        #expect(await grpc.expression == "UserService.GetUser")

        let children = await grpc.children
        #expect(children.count == 2)
        #expect(await children[0].kind == .payload)
        #expect(await children[1].kind == .`let`)

        guard case .grpc(let node) = await grpc.node else { Issue.record("Expected .grpc"); return }
        #expect(node.service == "UserService")
        #expect(node.rpcMethod == "GetUser")
        #expect(node.payloadFields.count == 1)
        #expect(node.payloadFields[0].key == "id")
        #expect(node.payloadFields[0].value == "userId")
        #expect(node.letBinding?.name == "user")
    }

    @Test func grpcWithMetadata() async throws {
        let logic = try await parse("""
            |> GRPC AuthService.ValidateToken
            |> PAYLOAD
            |  token = authToken
            |> METADATA
            |  x-request-id = requestId
            |  x-tenant = tenantId
            |> LET result = _
            """)
        guard case .grpc(let node) = await logic.statements[0].node else {
            Issue.record("Expected .grpc"); return
        }
        #expect(node.service == "AuthService")
        #expect(node.rpcMethod == "ValidateToken")
        #expect(node.payloadFields.count == 1)
        #expect(node.metadataFields.count == 2)
        #expect(node.metadataFields[0].key == "x-request-id")
        #expect(node.metadataFields[1].key == "x-tenant")
        #expect(node.letBinding?.name == "result")
    }

    @Test func grpcPayloadOnly() async throws {
        let logic = try await parse("""
            |> GRPC OrderService.CreateOrder
            |> PAYLOAD
            |  customerId = order.customerId
            |  amount = order.total
            |  items = order.items
            |> LET created = _
            """)
        guard case .grpc(let node) = await logic.statements[0].node else {
            Issue.record("Expected .grpc"); return
        }
        #expect(node.payloadFields.count == 3)
        #expect(node.metadataFields.isEmpty)
        #expect(node.letBinding?.name == "created")
    }

    @Test func grpcMetadataOnly() async throws {
        let logic = try await parse("""
            |> GRPC NotificationService.Push
            |> METADATA
            |  priority = "high"
            |> LET _ = _
            """)
        guard case .grpc(let node) = await logic.statements[0].node else {
            Issue.record("Expected .grpc"); return
        }
        #expect(node.payloadFields.isEmpty)
        #expect(node.metadataFields.count == 1)
        #expect(node.metadataFields[0].key == "priority")
    }

    @Test func grpcServiceMethodParsed() async throws {
        // Dot is used as separator; everything before the last dot is the service
        let logic = try await parse("""
            |> GRPC com.example.UserService.GetProfile
            |> LET profile = _
            """)
        guard case .grpc(let node) = await logic.statements[0].node else {
            Issue.record("Expected .grpc"); return
        }
        #expect(node.service == "com.example.UserService")
        #expect(node.rpcMethod == "GetProfile")
    }

    @Test func grpcFollowedByIndependentStatements() async throws {
        let logic = try await parse("""
            |> GRPC UserService.GetUser
            |> PAYLOAD
            |  id = userId
            |> LET user = _
            call audit(user)
            return user
            """)
        // grpc claims payload and let; call/return are independent
        #expect(logic.statements.count == 3)
        #expect(await logic.statements[0].kind == .grpc)
        #expect(await logic.statements[1].kind == .call)
        #expect(await logic.statements[2].kind == .`return`)
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}
