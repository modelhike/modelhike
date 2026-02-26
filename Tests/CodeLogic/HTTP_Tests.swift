import Testing
@testable import ModelHike

// MARK: - HTTP / REST / GraphQL / raw statement tests
//
// Covers: http (REST) · http-graphql · http-raw

@Suite("HTTP Statements") struct HTTP_Tests {

    // MARK: http — basic methods

    @Test func httpGet() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.example.com/users
            |> LET users = _
            return users
            """)
        #expect(logic.statements.count == 2)
        let http = logic.statements[0]
        #expect(await http.kind == .http)
        let children = await http.children
        #expect(children.count == 1)
        #expect(await children[0].kind == .`let`)

        guard case .http(let node) = await http.node else { Issue.record("Expected .http"); return }
        #expect(node.method == "GET")
        #expect(node.url == "https://api.example.com/users")
        #expect(node.letBinding?.name == "users")
    }

    @Test func httpPost() async throws {
        let logic = try await parse("""
            |> HTTP POST https://api.example.com/orders
            |> BODY
            |  customerId = order.customerId
            |  amount = order.amount
            |> EXPECT 201
            |> LET created = _
            """)
        #expect(logic.statements.count == 1)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.method == "POST")
        #expect(node.bodyFields.count == 2)
        #expect(node.bodyFields[0].key == "customerId")
        #expect(node.bodyFields[1].key == "amount")
        #expect(node.expectedStatus == "201")
        #expect(node.letBinding?.name == "created")
    }

    @Test func httpWithPathParams() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.example.com/users/{id}/orders
            |> PATH
            |  id = userId
            |> LET orders = _
            """)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.pathParams.count == 1)
        #expect(node.pathParams[0].key == "id")
        #expect(node.pathParams[0].value == "userId")
    }

    @Test func httpWithQueryParams() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.example.com/products
            |> QUERY
            |  page = pageNum
            |  size = pageSize
            |  sort = "name"
            |> LET products = _
            """)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.queryParams.count == 3)
        #expect(node.queryParams[0].key == "page")
        #expect(node.queryParams[2].key == "sort")
    }

    @Test func httpWithHeaders() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.internal.com/data
            |> HEADERS
            |  X-Tenant-Id = tenantId
            |  X-Request-Id = requestId
            |> LET data = _
            """)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.headerFields.count == 2)
        #expect(node.headerFields[0].key == "X-Tenant-Id")
    }

    @Test func httpWithAuth() async throws {
        let logic = try await parse("""
            |> HTTP GET https://api.example.com/profile
            |> AUTH bearer token
            |> EXPECT 200
            |> LET profile = _
            """)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.auth?.scheme == "bearer")
        #expect(node.auth?.credential == "token")
        #expect(node.expectedStatus == "200")
    }

    @Test func httpPutFull() async throws {
        let logic = try await parse("""
            |> HTTP PUT https://api.example.com/users/{id}
            |> PATH
            |  id = userId
            |> HEADERS
            |  Content-Type = application/json
            |> AUTH bearer accessToken
            |> BODY
            |  name = user.name
            |  email = user.email
            |> EXPECT 200
            |> LET updated = _
            return updated
            """)
        #expect(logic.statements.count == 2)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.method == "PUT")
        #expect(node.pathParams.count == 1)
        #expect(node.headerFields.count == 1)
        #expect(node.auth?.scheme == "bearer")
        #expect(node.bodyFields.count == 2)
        #expect(node.expectedStatus == "200")
        #expect(node.letBinding?.name == "updated")
    }

    @Test func httpDelete() async throws {
        let logic = try await parse("""
            |> HTTP DELETE https://api.example.com/sessions/{id}
            |> PATH
            |  id = sessionId
            |> AUTH bearer token
            |> EXPECT 204
            |> LET _ = _
            """)
        guard case .http(let node) = await logic.statements[0].node else {
            Issue.record("Expected .http"); return
        }
        #expect(node.method == "DELETE")
        #expect(node.expectedStatus == "204")
    }

    // MARK: http-graphql

    @Test func graphqlWithVariables() async throws {
        let logic = try await parse("""
            |> HTTP-GRAPHQL https://api.example.com/graphql
            |> QUERY
            |  query GetUser($id: ID!) { user(id: $id) { name email } }
            |> VARIABLES
            |  id = userId
            |> LET user = _
            """)
        #expect(logic.statements.count == 1)
        guard case .httpGraphQL(let node) = await logic.statements[0].node else {
            Issue.record("Expected .httpGraphQL"); return
        }
        #expect(node.url == "https://api.example.com/graphql")
        #expect(node.queryLines.count == 1)
        #expect(node.variables.count == 1)
        #expect(node.variables[0].key == "id")
        #expect(node.variables[0].value == "userId")
        #expect(node.letBinding?.name == "user")
    }

    @Test func graphqlWithAuthAndExpect() async throws {
        let logic = try await parse("""
            |> HTTP-GRAPHQL https://api.example.com/graphql
            |> QUERY
            |  mutation CreateOrder($input: OrderInput!) { createOrder(input: $input) { id } }
            |> VARIABLES
            |  input = orderInput
            |> AUTH bearer token
            |> EXPECT 200
            |> LET result = _
            """)
        guard case .httpGraphQL(let node) = await logic.statements[0].node else {
            Issue.record("Expected .httpGraphQL"); return
        }
        #expect(node.auth?.scheme == "bearer")
        #expect(node.expectedStatus == "200")
        #expect(node.variables.count == 1)
    }

    // MARK: http-raw

    @Test func httpRawWithRawBlock() async throws {
        // Lines inside raw> / note> blocks: unknown first-word → full content stored as expression.
        // Avoid words that are recognised Midlang keywords (e.g. "return", "call", "filter").
        let logic = try await parse("""
            |> HTTP-RAW curl
            |> RAW
            |  GET https://example.com/api -H "Accept: application/json"
            |> NOTE
            |  Needs an API-Key header
            """)
        #expect(logic.statements.count == 1)
        guard case .httpRaw(let node) = await logic.statements[0].node else {
            Issue.record("Expected .httpRaw"); return
        }
        #expect(node.source == "curl")
        #expect(node.rawLines.count == 1)
        #expect(node.rawLines[0].contains("example.com"))
        #expect(node.notes.count == 1)
        #expect(node.notes[0].contains("API-Key"))
    }

    // MARK: Helper

    private func parse(_ dslString: String) async throws -> CodeLogic {
        let logic = await CodeLogicParser.parse(dslString: dslString)
        return try #require(logic)
    }
}
