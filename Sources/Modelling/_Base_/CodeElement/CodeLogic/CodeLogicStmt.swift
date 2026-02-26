//
//  CodeLogicStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// A single node in a method's logic tree, corresponding to one pipe-gutter statement.
///
/// Every statement kind has a dedicated `Node` case backed by its own struct. Block-opening
/// nodes (e.g. `db>`, `http>`, `grpc>`) absorb their expected child sub-nodes into typed fields
/// at construction time, so emitters never need to walk `children` manually.
///
/// Sub-block node structs are nested inside their owning parent struct:
/// - `DbQueryNode.WhereNode`, `.IncludeNode`, `.OrderByNode`, etc.
/// - `DbUpdateNode.SetFieldNode`
/// - `DbRawNode.SqlNode`, `.ParamsNode`
/// - `HttpNode.PathNode`, `.QueryNode`, `.HeadersNode`, `.AuthNode`, `.ExpectNode`, `.BodyNode`
/// - `HttpGraphQLNode.VariablesNode`
/// - `GrpcNode.PayloadNode`, `.MetadataNode`
/// - `HttpRawNode.NoteNode`
///
/// Both `children` and `node` are `let` (nonisolated), so they are readable without `await`.
public actor CodeLogicStmt {
    public let kind: CodeLogicStmtKind
    /// Raw expression string following the keyword (retained for diagnostics and fallback).
    public let expression: String
    /// Nested statements at the next depth level (set once at construction, never mutated).
    public let children: [CodeLogicStmt]
    /// Fully structured AST node, built synchronously from `kind`, `expression`, and `children`.
    public let node: Node

    public init(kind: CodeLogicStmtKind, expression: String = "", children: [CodeLogicStmt] = []) {
        self.kind       = kind
        self.expression = expression
        self.children   = children
        self.node       = Node.parse(kind: kind, expression: expression, children: children)
    }
}

// MARK: - AST Node enum

extension CodeLogicStmt {

    public enum Node: Sendable {

        // MARK: Control flow
        case ifStmt(IfNode)
        case elseIfStmt(IfNode.ElseIfNode)
        case elseBranch(IfNode.ElseNode)
        case forLoop(ForLoopNode)
        case whileLoop(WhileNode)
        case tryBlock(TryNode)
        case catchClause(TryNode.CatchNode)
        case finallyBlock(TryNode.FinallyNode)
        case switchStmt(SwitchNode)
        case caseClause(SwitchNode.CaseNode)
        case defaultCase(SwitchNode.DefaultNode)
        case compilerDirectiveIf(CompilerIfNode)
        case compilerElseBranch(CompilerIfNode.ElseNode)
        case compilerEndDirective(CompilerIfNode.EndIfNode)

        // MARK: Core imperatives
        case call(CallNode)
        case assign(AssignNode)
        case returnStmt(ReturnNode)
        case expr(ExprNode)
        case raw(RawNode)

        // MARK: Functional / pipelines
        case pipe(PipeNode)
        case filter(FilterNode)
        case select(SelectNode)
        case map(MapNode)
        case reduce(ReduceNode)
        case letBinding(LetNode)
        case match(MatchNode)
        case when(WhenNode)
        case endMatch(EndMatchNode)

        // MARK: Database — query chain
        /// Owns: `.dbWhere`, `.include`, `.orderBy`, `.skip`, `.take`,
        ///       `.toList`/`.first`/`.single`, `.letBinding`
        case db(DbQueryNode)
        case dbWhere(DbQueryNode.WhereNode)
        case include(DbQueryNode.IncludeNode)
        case orderBy(DbQueryNode.OrderByNode)
        case skip(DbQueryNode.SkipNode)
        case take(DbQueryNode.TakeNode)
        case toList(DbQueryNode.ToListNode)
        case first(DbQueryNode.FirstNode)
        case single(DbQueryNode.SingleNode)

        // MARK: Database — mutations
        case dbInsert(DbInsertNode)
        /// Owns: `.setField` siblings
        case dbUpdate(DbUpdateNode)
        case dbDelete(DbDeleteNode)
        case setField(DbUpdateNode.SetFieldNode)

        // MARK: Database — aggregation, procs, raw
        case groupBy(GroupByNode)
        case aggregate(AggregateNode)
        /// Owns: `DbRawNode.ParamsNode` (via `params>` sibling), `.letBinding`
        case dbProcCall(DbProcCallNode)
        /// Owns: parsed `params: [AssignNode.FieldPair]`
        case dbParams(DbRawNode.ParamsNode)
        /// Owns: parsed `lines: [String]`
        case dbSql(DbRawNode.SqlNode)
        /// Owns: `.dbSql` + `.dbParams` siblings
        case dbRaw(DbRawNode)

        // MARK: HTTP / REST
        /// Owns: `.httpPath`, `.httpQuery`, `.httpHeaders`, `.httpAuth`,
        ///       `.httpExpect`, `.httpBody`, `.letBinding`
        case http(HttpNode)
        /// Owns: parsed `params: [AssignNode.FieldPair]`
        case httpPath(HttpNode.PathNode)
        /// Owns: parsed `params: [AssignNode.FieldPair]` (REST) or `lines: [String]` (GraphQL)
        case httpQuery(HttpNode.QueryNode)
        /// Owns: parsed `fields: [AssignNode.FieldPair]`
        case httpHeaders(HttpNode.HeadersNode)
        case httpAuth(HttpNode.AuthNode)
        case httpExpect(HttpNode.ExpectNode)
        /// Owns: parsed `fields: [AssignNode.FieldPair]`
        case httpBody(HttpNode.BodyNode)
        /// Owns: `.httpQuery`, `.httpVariables`, `.httpAuth`, `.httpExpect`, `.letBinding`
        case httpGraphQL(HttpGraphQLNode)
        /// Owns: parsed `variables: [AssignNode.FieldPair]`
        case httpVariables(HttpGraphQLNode.VariablesNode)
        /// Owns: `.raw` + `.note` siblings
        case httpRaw(HttpRawNode)

        // MARK: gRPC
        /// Owns: `.grpcPayload`, `.grpcMetadata`, `.letBinding`
        case grpc(GrpcNode)
        /// Owns: parsed `fields: [AssignNode.FieldPair]`
        case grpcPayload(GrpcNode.PayloadNode)
        /// Owns: parsed `fields: [AssignNode.FieldPair]`
        case grpcMetadata(GrpcNode.MetadataNode)

        // MARK: Annotation
        /// Owns: parsed `lines: [String]` from children
        case note(HttpRawNode.NoteNode)

        // MARK: Fallback
        case unknown(UnknownNode)
    }
}

// MARK: - Control flow nodes

extension CodeLogicStmt {

    public struct ForLoopNode: Sendable  { public let item: String; public let collection: String }
    public struct WhileNode: Sendable    { public let condition: String }

    public struct TryNode: Sendable {
        public init() {}

        // MARK: Sub-nodes
        public struct CatchNode: Sendable   { public let variable: String; public let type: String? }
        public struct FinallyNode: Sendable { public init() {} }
    }

    public struct IfNode: Sendable {
        public let condition: String

        // MARK: Sub-nodes
        public struct ElseIfNode: Sendable { public let condition: String }
        public struct ElseNode: Sendable   { public init() {} }
    }

    public struct SwitchNode: Sendable {
        public let subject: String

        // MARK: Sub-nodes
        public struct CaseNode: Sendable    { public let value: String }
        public struct DefaultNode: Sendable { public init() {} }
    }

    public struct CompilerIfNode: Sendable {
        public let symbol: String

        // MARK: Sub-nodes
        public struct ElseNode: Sendable  { public init() {} }
        public struct EndIfNode: Sendable { public init() {} }
    }
}

// MARK: - Core imperative nodes

extension CodeLogicStmt {

    public struct CallNode: Sendable   { public let callExpression: String }
    public struct ReturnNode: Sendable { public let expression: String }
    public struct ExprNode: Sendable   { public let expression: String }

    public struct AssignNode: Sendable {
        public let lhs: String
        public let rhs: String

        /// A key=value pair parsed from an `assign>` child statement.
        public struct FieldPair: Sendable {
            public let key: String
            public let value: String
        }
    }

    /// `raw>` — verbatim source block; depth+1 children provide multi-line content.
    public struct RawNode: Sendable {
        public let content: String
        public let lines: [String]

        public init(content: String, lines: [String] = []) {
            self.content = content
            self.lines   = lines
        }

        static func parse(content: String, from children: [CodeLogicStmt]) -> RawNode {
            RawNode(content: content, lines: children.compactMap { $0.expression.blankToNil })
        }
    }
}

// MARK: - Functional / pipeline nodes

extension CodeLogicStmt {

    public struct PipeNode: Sendable    { public let source: String }
    public struct FilterNode: Sendable  { public let lambda: String }
    public struct SelectNode: Sendable  { public let lambda: String }
    public struct MapNode: Sendable     { public let lambda: String }
    public struct ReduceNode: Sendable  { public let expression: String }
    public struct LetNode: Sendable     { public let name: String }
    public struct MatchNode: Sendable   { public let expression: String }
    public struct WhenNode: Sendable    { public let pattern: String }
    public struct EndMatchNode: Sendable { public init() {} }
}

// MARK: - DbQueryNode

extension CodeLogicStmt {

    /// `db> Entity` — claims `where>`, `include>`, `order-by>`, `skip>`, `take>`,
    /// `to-list>`/`first>`/`single>` as same-depth siblings and absorbs them into typed fields.
    public struct DbQueryNode: Sendable {
        public let entity: String
        public let where_: WhereNode?
        public let includes: [IncludeNode]
        public let orderBy: OrderByNode?
        public let skip: SkipNode?
        public let take: TakeNode?
        public let materialize: Materialize?
        public let letBinding: LetNode?

        public enum Materialize: Sendable { case toList, first, single }

        // MARK: Sub-nodes
        public struct WhereNode: Sendable   { public let lambda: String }
        public struct IncludeNode: Sendable { public let relation: String }
        public struct SkipNode: Sendable    { public let count: String }
        public struct TakeNode: Sendable    { public let count: String }
        public struct ToListNode: Sendable  { public init() {} }
        public struct FirstNode: Sendable   { public init() {} }
        public struct SingleNode: Sendable  { public init() {} }

        public struct OrderByNode: Sendable {
            public enum Direction: String, Sendable { case asc, desc }
            public let expression: String
            public let direction: Direction
        }

        public init(entity: String,
                    where_: WhereNode? = nil, includes: [IncludeNode] = [],
                    orderBy: OrderByNode? = nil, skip: SkipNode? = nil, take: TakeNode? = nil,
                    materialize: Materialize? = nil, letBinding: LetNode? = nil) {
            self.entity      = entity
            self.where_      = where_
            self.includes    = includes
            self.orderBy     = orderBy
            self.skip        = skip
            self.take        = take
            self.materialize = materialize
            self.letBinding  = letBinding
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [
            .where, .include, .orderBy, .skip, .take, .toList, .first, .single, .let
        ]

        static func parse(entity: String, from children: [CodeLogicStmt]) -> DbQueryNode {
            var where_: WhereNode?
            var includes: [IncludeNode] = []
            var orderBy: OrderByNode?
            var skip: SkipNode?
            var take: TakeNode?
            var materialize: Materialize?
            var letBinding: LetNode?

            for child in children {
                switch child.kind {
                case .where:   where_ = .init(lambda: child.expression)
                case .include: includes.append(.init(relation: child.expression))
                case .orderBy:
                    let (rest, last) = child.expression.splittingOffLastWord()
                    switch last.lowercased() {
                    case "desc": orderBy = .init(expression: rest, direction: .desc)
                    case "asc":  orderBy = .init(expression: rest, direction: .asc)
                    default:     orderBy = .init(expression: child.expression, direction: .asc)
                    }
                case .skip:   skip = .init(count: child.expression)
                case .take:   take = .init(count: child.expression)
                case .toList: materialize = .toList
                case .first:  materialize = .first
                case .single: materialize = .single
                case .let:
                    let name = child.expression.slicing(around: " = ").lhs
                    letBinding = .init(name: name.blankToNil ?? child.expression)
                default: break
                }
            }
            return DbQueryNode(entity: entity, where_: where_, includes: includes,
                               orderBy: orderBy, skip: skip, take: take,
                               materialize: materialize, letBinding: letBinding)
        }
    }
}

// MARK: - Database mutation nodes

extension CodeLogicStmt {

    public struct DbInsertNode: Sendable {
        public let entity: String
        public let source: String
    }

    public struct DbDeleteNode: Sendable {
        public let entity: String
        public let predicate: String
    }

    /// `db-update> Entity -> predicate` — claims `set>` siblings and absorbs them into `fields`.
    public struct DbUpdateNode: Sendable {
        public let entity: String
        public let predicate: String
        public let fields: [AssignNode.FieldPair]

        // MARK: Sub-node
        public struct SetFieldNode: Sendable {
            public let field: String
            public let value: String
        }

        public init(entity: String, predicate: String, fields: [AssignNode.FieldPair] = []) {
            self.entity    = entity
            self.predicate = predicate
            self.fields    = fields
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [.set]

        static func parse(entity: String, predicate: String,
                          from children: [CodeLogicStmt]) -> DbUpdateNode {
            let fields: [AssignNode.FieldPair] = children.compactMap { child in
                guard child.kind == .set else { return nil }
                let p = child.expression.slicing(around: " = ")
                return AssignNode.FieldPair(key: p.lhs, value: p.rhs)
            }
            return DbUpdateNode(entity: entity, predicate: predicate, fields: fields)
        }
    }
}

// MARK: - Database aggregation nodes

extension CodeLogicStmt {

    public struct GroupByNode: Sendable   { public let lambda: String }
    public struct AggregateNode: Sendable { public let function: String }
}

// MARK: - DbProcCallNode

extension CodeLogicStmt {

    /// `db-proc-call> schema.ProcName` — claims `params>` sibling and absorbs into `params`.
    public struct DbProcCallNode: Sendable {
        public let procedure: String
        public let params: [AssignNode.FieldPair]
        public let letBinding: LetNode?

        public init(procedure: String, params: [AssignNode.FieldPair] = [],
                    letBinding: LetNode? = nil) {
            self.procedure  = procedure
            self.params     = params
            self.letBinding = letBinding
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [.params, .let]

        static func parse(procedure: String, from children: [CodeLogicStmt]) -> DbProcCallNode {
            var params: [AssignNode.FieldPair] = []
            var letBinding: LetNode?
            for child in children {
                switch child.kind {
                case .params:
                    params = parseKV(from: child.children)
                case .let:
                    let name = child.expression.slicing(around: " = ").lhs
                    letBinding = .init(name: name.blankToNil ?? child.expression)
                default: break
                }
            }
            return DbProcCallNode(procedure: procedure, params: params, letBinding: letBinding)
        }
    }
}

// MARK: - DbRawNode

extension CodeLogicStmt {

    /// `db-raw> source` — claims `params>` and `sql>` siblings; absorbs into typed fields.
    public struct DbRawNode: Sendable {
        public let source: String
        public let sqlLines: [String]
        public let params: [AssignNode.FieldPair]

        // MARK: Sub-nodes
        /// `params>` — depth+1 children are `assign` statements.
        public struct ParamsNode: Sendable {
            public let params: [AssignNode.FieldPair]
            public init(params: [AssignNode.FieldPair] = []) { self.params = params }
            static func parse(from children: [CodeLogicStmt]) -> ParamsNode {
                ParamsNode(params: parseKV(from: children))
            }
        }
        /// `sql>` — depth+1 children are verbatim text lines.
        public struct SqlNode: Sendable {
            public let lines: [String]
            public init(lines: [String] = []) { self.lines = lines }
            static func parse(from children: [CodeLogicStmt]) -> SqlNode {
                SqlNode(lines: children.compactMap { $0.expression.blankToNil })
            }
        }

        public init(source: String, sqlLines: [String] = [], params: [AssignNode.FieldPair] = []) {
            self.source   = source
            self.sqlLines = sqlLines
            self.params   = params
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [.params, .sql]

        static func parse(source: String, from children: [CodeLogicStmt]) -> DbRawNode {
            var sqlLines: [String] = []
            var params: [AssignNode.FieldPair] = []
            for child in children {
                switch child.kind {
                case .sql:    sqlLines = child.children.compactMap { $0.expression.blankToNil }
                case .params: params   = parseKV(from: child.children)
                default: break
                }
            }
            return DbRawNode(source: source, sqlLines: sqlLines, params: params)
        }
    }
}

// MARK: - HttpNode

extension CodeLogicStmt {

    /// `http> METHOD url` — claims `path>`, `query>`, `headers>`, `auth>`, `expect>`, `body>`
    /// as same-depth siblings and absorbs them into typed fields.
    public struct HttpNode: Sendable {
        public let method: String
        public let url: String
        public let pathParams: [AssignNode.FieldPair]
        public let queryParams: [AssignNode.FieldPair]
        public let headerFields: [AssignNode.FieldPair]
        public let auth: AuthNode?
        public let expectedStatus: String?
        public let bodyFields: [AssignNode.FieldPair]
        public let letBinding: LetNode?

        // MARK: Sub-nodes
        /// `path>` — depth+1 children are `assign` path-param statements.
        public struct PathNode: Sendable {
            public let params: [AssignNode.FieldPair]
            public init(params: [AssignNode.FieldPair] = []) { self.params = params }
            static func parse(from children: [CodeLogicStmt]) -> PathNode {
                PathNode(params: parseKV(from: children))
            }
        }
        /// `query>` — depth+1 children are `assign` pairs (REST) or raw lines (GraphQL body).
        public struct QueryNode: Sendable {
            public let params: [AssignNode.FieldPair]
            public let lines: [String]
            public init(params: [AssignNode.FieldPair] = [], lines: [String] = []) {
                self.params = params
                self.lines  = lines
            }
            static func parse(from children: [CodeLogicStmt]) -> QueryNode {
                var params: [AssignNode.FieldPair] = []
                var lines: [String] = []
                for child in children {
                    if child.kind == .assign {
                        let p = child.expression.slicing(around: " = ")
                        params.append(.init(key: p.lhs, value: p.rhs))
                    } else if let e = child.expression.blankToNil {
                        lines.append(e)
                    }
                }
                return QueryNode(params: params, lines: lines)
            }
        }
        /// `headers>` — depth+1 children are `assign` header statements.
        public struct HeadersNode: Sendable {
            public let fields: [AssignNode.FieldPair]
            public init(fields: [AssignNode.FieldPair] = []) { self.fields = fields }
            static func parse(from children: [CodeLogicStmt]) -> HeadersNode {
                HeadersNode(fields: parseKV(from: children))
            }
        }
        /// `auth>` — inline `scheme credential` expression; no children.
        public struct AuthNode: Sendable {
            public let scheme: String
            public let credential: String
        }
        /// `expect>` — inline HTTP status code expression; no children.
        public struct ExpectNode: Sendable {
            public let statusCode: String
        }
        /// `body>` — depth+1 children are `assign` body-field statements.
        public struct BodyNode: Sendable {
            public let fields: [AssignNode.FieldPair]
            public init(fields: [AssignNode.FieldPair] = []) { self.fields = fields }
            static func parse(from children: [CodeLogicStmt]) -> BodyNode {
                BodyNode(fields: parseKV(from: children))
            }
        }

        public init(method: String, url: String,
                    pathParams: [AssignNode.FieldPair] = [], queryParams: [AssignNode.FieldPair] = [],
                    headerFields: [AssignNode.FieldPair] = [], auth: AuthNode? = nil,
                    expectedStatus: String? = nil, bodyFields: [AssignNode.FieldPair] = [],
                    letBinding: LetNode? = nil) {
            self.method         = method
            self.url            = url
            self.pathParams     = pathParams
            self.queryParams    = queryParams
            self.headerFields   = headerFields
            self.auth           = auth
            self.expectedStatus = expectedStatus
            self.bodyFields     = bodyFields
            self.letBinding     = letBinding
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [
            .path, .query, .headers, .auth, .expect, .body, .let
        ]

        static func parse(expression: String, from children: [CodeLogicStmt]) -> HttpNode {
            let (method, url) = expression.splittingOffFirstWord()
            var pathParams: [AssignNode.FieldPair] = []
            var queryParams: [AssignNode.FieldPair] = []
            var headerFields: [AssignNode.FieldPair] = []
            var auth: AuthNode?
            var expectedStatus: String?
            var bodyFields: [AssignNode.FieldPair] = []
            var letBinding: LetNode?

            for child in children {
                switch child.kind {
                case .path:
                    pathParams = parseKV(from: child.children)
                case .query:
                    queryParams = parseKV(from: child.children)
                case .headers:
                    headerFields = parseKV(from: child.children)
                case .auth:
                    let (scheme, cred) = child.expression.splittingOffFirstWord()
                    auth = .init(scheme: scheme, credential: cred)
                case .expect:
                    expectedStatus = child.expression
                case .body:
                    bodyFields = parseKV(from: child.children)
                case .let:
                    let name = child.expression.slicing(around: " = ").lhs
                    letBinding = .init(name: name.blankToNil ?? child.expression)
                default: break
                }
            }
            return HttpNode(method: method.uppercased(), url: url,
                            pathParams: pathParams, queryParams: queryParams,
                            headerFields: headerFields, auth: auth,
                            expectedStatus: expectedStatus, bodyFields: bodyFields,
                            letBinding: letBinding)
        }
    }
}

// MARK: - HttpGraphQLNode

extension CodeLogicStmt {

    /// `http-graphql> url` — claims `query>`, `variables>`, `auth>`, `expect>` siblings.
    public struct HttpGraphQLNode: Sendable {
        public let url: String
        public let queryLines: [String]
        public let variables: [AssignNode.FieldPair]
        public let auth: HttpNode.AuthNode?
        public let expectedStatus: String?
        public let letBinding: LetNode?

        // MARK: Sub-node
        /// `variables>` — depth+1 children are `assign` GraphQL-variable statements.
        public struct VariablesNode: Sendable {
            public let variables: [AssignNode.FieldPair]
            public init(variables: [AssignNode.FieldPair] = []) { self.variables = variables }
            static func parse(from children: [CodeLogicStmt]) -> VariablesNode {
                VariablesNode(variables: parseKV(from: children))
            }
        }

        public init(url: String, queryLines: [String] = [], variables: [AssignNode.FieldPair] = [],
                    auth: HttpNode.AuthNode? = nil, expectedStatus: String? = nil,
                    letBinding: LetNode? = nil) {
            self.url            = url
            self.queryLines     = queryLines
            self.variables      = variables
            self.auth           = auth
            self.expectedStatus = expectedStatus
            self.letBinding     = letBinding
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [
            .query, .variables, .auth, .expect, .let
        ]

        static func parse(url: String, from children: [CodeLogicStmt]) -> HttpGraphQLNode {
            var queryLines: [String] = []
            var variables: [AssignNode.FieldPair] = []
            var auth: HttpNode.AuthNode?
            var expectedStatus: String?
            var letBinding: LetNode?

            for child in children {
                switch child.kind {
                case .query:
                    queryLines = child.children.compactMap { $0.expression.blankToNil }
                case .variables:
                    variables = parseKV(from: child.children)
                case .auth:
                    let (scheme, cred) = child.expression.splittingOffFirstWord()
                    auth = .init(scheme: scheme, credential: cred)
                case .expect:
                    expectedStatus = child.expression
                case .let:
                    let name = child.expression.slicing(around: " = ").lhs
                    letBinding = .init(name: name.blankToNil ?? child.expression)
                default: break
                }
            }
            return HttpGraphQLNode(url: url, queryLines: queryLines, variables: variables,
                                   auth: auth, expectedStatus: expectedStatus,
                                   letBinding: letBinding)
        }
    }
}

// MARK: - HttpRawNode

extension CodeLogicStmt {

    /// `http-raw> source` — claims `raw>` and `note>` siblings; absorbs into typed fields.
    public struct HttpRawNode: Sendable {
        public let source: String
        public let rawLines: [String]
        public let notes: [String]

        // MARK: Sub-node
        /// `note> content` — depth+1 children provide multi-line note text.
        public struct NoteNode: Sendable {
            public let content: String
            public let lines: [String]
            public init(content: String, lines: [String] = []) {
                self.content = content
                self.lines   = lines
            }
            static func parse(content: String, from children: [CodeLogicStmt]) -> NoteNode {
                NoteNode(content: content, lines: children.compactMap { $0.expression.blankToNil })
            }
        }

        public init(source: String, rawLines: [String] = [], notes: [String] = []) {
            self.source   = source
            self.rawLines = rawLines
            self.notes    = notes
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [.raw, .note]

        static func parse(source: String, from children: [CodeLogicStmt]) -> HttpRawNode {
            var rawLines: [String] = []
            var notes: [String] = []
            for child in children {
                switch child.kind {
                case .raw:
                    let nested = child.children.compactMap { $0.expression.blankToNil }
                    rawLines = nested.isEmpty ? (child.expression.blankToNil.map { [$0] } ?? []) : nested
                case .note:
                    let nested = child.children.compactMap { $0.expression.blankToNil }
                    let content = nested.isEmpty ? (child.expression.blankToNil.map { [$0] } ?? []) : nested
                    notes.append(contentsOf: content)
                default: break
                }
            }
            return HttpRawNode(source: source, rawLines: rawLines, notes: notes)
        }
    }
}

// MARK: - GrpcNode

extension CodeLogicStmt {

    /// `grpc> Service.Method` — claims `payload>` and `metadata>` siblings.
    public struct GrpcNode: Sendable {
        public let service: String
        public let rpcMethod: String
        public let payloadFields: [AssignNode.FieldPair]
        public let metadataFields: [AssignNode.FieldPair]
        public let letBinding: LetNode?

        // MARK: Sub-nodes
        /// `payload>` — depth+1 children are `assign` request-field statements.
        public struct PayloadNode: Sendable {
            public let fields: [AssignNode.FieldPair]
            public init(fields: [AssignNode.FieldPair] = []) { self.fields = fields }
            static func parse(from children: [CodeLogicStmt]) -> PayloadNode {
                PayloadNode(fields: parseKV(from: children))
            }
        }
        /// `metadata>` — depth+1 children are `assign` metadata key=value statements.
        public struct MetadataNode: Sendable {
            public let fields: [AssignNode.FieldPair]
            public init(fields: [AssignNode.FieldPair] = []) { self.fields = fields }
            static func parse(from children: [CodeLogicStmt]) -> MetadataNode {
                MetadataNode(fields: parseKV(from: children))
            }
        }

        public init(service: String, rpcMethod: String,
                    payloadFields: [AssignNode.FieldPair] = [],
                    metadataFields: [AssignNode.FieldPair] = [],
                    letBinding: LetNode? = nil) {
            self.service        = service
            self.rpcMethod      = rpcMethod
            self.payloadFields  = payloadFields
            self.metadataFields = metadataFields
            self.letBinding     = letBinding
        }

        static let siblingChildKinds: Set<CodeLogicStmtKind> = [.payload, .metadata, .let]

        static func parse(service: String, rpcMethod: String,
                          from children: [CodeLogicStmt]) -> GrpcNode {
            var payloadFields: [AssignNode.FieldPair] = []
            var metadataFields: [AssignNode.FieldPair] = []
            var letBinding: LetNode?

            for child in children {
                switch child.kind {
                case .payload:  payloadFields  = parseKV(from: child.children)
                case .metadata: metadataFields = parseKV(from: child.children)
                case .let:
                    let name = child.expression.slicing(around: " = ").lhs
                    letBinding = .init(name: name.blankToNil ?? child.expression)
                default: break
                }
            }
            return GrpcNode(service: service, rpcMethod: rpcMethod,
                            payloadFields: payloadFields, metadataFields: metadataFields,
                            letBinding: letBinding)
        }
    }
}

// MARK: - Fallback node

extension CodeLogicStmt {

    public struct UnknownNode: Sendable { public let raw: String }
}

// MARK: - Node factory

extension CodeLogicStmt.Node {

    /// Single unified factory — called synchronously from `CodeLogicStmt.init`.
    /// Block nodes absorb siblings/children into typed fields; leaf nodes parse their expression.
    static func parse(kind: CodeLogicStmtKind, expression: String,
                      children: [CodeLogicStmt]) -> CodeLogicStmt.Node {
        switch kind {

        // MARK: Control flow
        case .if:     return .ifStmt(.init(condition: expression))
        case .elseIf: return .elseIfStmt(.init(condition: expression))
        case .else:   return .elseBranch(.init())
        case .for:
            let p = expression.slicing(around: " in ")
            return .forLoop(.init(item: p.lhs, collection: p.rhs))
        case .while:         return .whileLoop(.init(condition: expression))
        case .try:    return .tryBlock(.init())
        case .catch:
            let p = expression.slicing(around: ":")
            return .catchClause(.init(variable: p.lhs, type: p.rhs.blankToNil))
        case .finally: return .finallyBlock(.init())
        case .switch:  return .switchStmt(.init(subject: expression))
        case .case:    return .caseClause(.init(value: expression))
        case .default: return .defaultCase(.init())
        case .compilerIf:    return .compilerDirectiveIf(.init(symbol: expression))
        case .compilerElse:  return .compilerElseBranch(.init())
        case .compilerEndIf: return .compilerEndDirective(.init())


        // MARK: Core imperatives
        case .call:   return .call(.init(callExpression: expression))
        case .assign:
            let p = expression.slicing(around: " = ")
            return .assign(.init(lhs: p.lhs, rhs: p.rhs))
        case .return: return .returnStmt(.init(expression: expression))
        case .expr:   return .expr(.init(expression: expression))
        case .raw:    return .raw(CodeLogicStmt.RawNode.parse(content: expression, from: children))

        // MARK: Functional / pipelines
        case .pipe:   return .pipe(.init(source: expression))
        case .filter: return .filter(.init(lambda: expression))
        case .select: return .select(.init(lambda: expression))
        case .map:    return .map(.init(lambda: expression))
        case .reduce: return .reduce(.init(expression: expression))
        case .let:
            let name = expression.slicing(around: " = ").lhs
            return .letBinding(.init(name: name.blankToNil ?? expression))
        case .match:    return .match(.init(expression: expression))
        case .when:     return .when(.init(pattern: expression))
        case .endMatch: return .endMatch(.init())

        // MARK: Database — query chain
        case .db:      return .db(CodeLogicStmt.DbQueryNode.parse(entity: expression, from: children))
        case .where:   return .dbWhere(.init(lambda: expression))
        case .include: return .include(.init(relation: expression))
        case .orderBy:
            let (rest, last) = expression.splittingOffLastWord()
            switch last.lowercased() {
            case "desc": return .orderBy(.init(expression: rest, direction: .desc))
            case "asc":  return .orderBy(.init(expression: rest, direction: .asc))
            default:     return .orderBy(.init(expression: expression, direction: .asc))
            }
        case .skip:   return .skip(.init(count: expression))
        case .take:   return .take(.init(count: expression))
        case .toList: return .toList(.init())
        case .first:  return .first(.init())
        case .single: return .single(.init())

        // MARK: Database — mutations
        case .dbInsert:
            let p = expression.slicing(around: " -> ")
            return .dbInsert(.init(entity: p.lhs, source: p.rhs))
        case .dbUpdate:
            let p = expression.slicing(around: " -> ")
            return .dbUpdate(CodeLogicStmt.DbUpdateNode.parse(entity: p.lhs, predicate: p.rhs, from: children))
        case .dbDelete:
            let p = expression.slicing(around: " -> ")
            return .dbDelete(.init(entity: p.lhs, predicate: p.rhs))
        case .set:
            let p = expression.slicing(around: " = ")
            return .setField(.init(field: p.lhs, value: p.rhs))

        // MARK: Database — aggregation, procs, raw
        case .groupBy:    return .groupBy(.init(lambda: expression))
        case .aggregate:  return .aggregate(.init(function: expression))
        case .dbProcCall: return .dbProcCall(CodeLogicStmt.DbProcCallNode.parse(procedure: expression, from: children))
        case .params:     return .dbParams(CodeLogicStmt.DbRawNode.ParamsNode.parse(from: children))
        case .sql:        return .dbSql(CodeLogicStmt.DbRawNode.SqlNode.parse(from: children))
        case .dbRaw:      return .dbRaw(CodeLogicStmt.DbRawNode.parse(source: expression, from: children))

        // MARK: HTTP / REST
        case .http:        return .http(CodeLogicStmt.HttpNode.parse(expression: expression, from: children))
        case .path:        return .httpPath(CodeLogicStmt.HttpNode.PathNode.parse(from: children))
        case .query:       return .httpQuery(CodeLogicStmt.HttpNode.QueryNode.parse(from: children))
        case .headers:     return .httpHeaders(CodeLogicStmt.HttpNode.HeadersNode.parse(from: children))
        case .auth:
            let (scheme, cred) = expression.splittingOffFirstWord()
            return .httpAuth(.init(scheme: scheme, credential: cred))
        case .expect:      return .httpExpect(.init(statusCode: expression))
        case .body:        return .httpBody(CodeLogicStmt.HttpNode.BodyNode.parse(from: children))
        case .httpGraphQL: return .httpGraphQL(CodeLogicStmt.HttpGraphQLNode.parse(url: expression, from: children))
        case .variables:   return .httpVariables(CodeLogicStmt.HttpGraphQLNode.VariablesNode.parse(from: children))
        case .httpRaw:     return .httpRaw(CodeLogicStmt.HttpRawNode.parse(source: expression, from: children))

        // MARK: gRPC
        case .grpc:
            let (svc, method) = expression.splittingOffLastComponent(separator: ".")
            return .grpc(CodeLogicStmt.GrpcNode.parse(service: svc, rpcMethod: method, from: children))
        case .payload:  return .grpcPayload(CodeLogicStmt.GrpcNode.PayloadNode.parse(from: children))
        case .metadata: return .grpcMetadata(CodeLogicStmt.GrpcNode.MetadataNode.parse(from: children))

        // MARK: Annotation
        case .note: return .note(CodeLogicStmt.HttpRawNode.NoteNode.parse(content: expression, from: children))

        // MARK: Fallback
        case .unknown: return .unknown(.init(raw: expression))
        }
    }
}

// MARK: - Shared KV helper

/// Extracts `assign>` children into `FieldPair` values. File-private so all node `parse`
/// methods can call it regardless of which extension they live in.
private func parseKV(from children: [CodeLogicStmt]) -> [CodeLogicStmt.AssignNode.FieldPair] {
    children.compactMap { child in
        // Accepts explicit `assign key = value` and bare `key = value` inside parameter blocks.
        guard child.kind == .assign || child.kind == .unknown else { return nil }
        let p = child.expression.slicing(around: " = ")
        guard !p.lhs.isEmpty else { return nil }
        return .init(key: p.lhs, value: p.rhs)
    }
}

// MARK: - Private string parsing helpers

private extension String {

    func slicing(around separator: String) -> (lhs: String, rhs: String) {
        guard let range = range(of: separator) else {
            return (trimmingCharacters(in: .whitespaces), "")
        }
        return (
            String(self[startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces),
            String(self[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        )
    }

    func splittingOffFirstWord() -> (first: String, rest: String) {
        guard let range = rangeOfCharacter(from: .whitespaces) else { return (self, "") }
        return (
            String(self[startIndex..<range.lowerBound]),
            String(self[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        )
    }

    func splittingOffLastWord() -> (rest: String, lastWord: String) {
        guard let range = rangeOfCharacter(from: .whitespaces, options: .backwards) else {
            return ("", self)
        }
        return (String(self[startIndex..<range.lowerBound]),
                String(self[range.upperBound...]))
    }

    func splittingOffLastComponent(separator: Character) -> (prefix: String, suffix: String) {
        guard let idx = lastIndex(of: separator) else { return ("", self) }
        return (String(self[startIndex..<idx]), String(self[index(after: idx)...]))
    }

    var blankToNil: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
