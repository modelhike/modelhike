//
//  CodeLogicStmtKind.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// The type of a single pipe-gutter logic statement, following the Midlang IR syntax.
///
/// Statements are grouped into: control-flow, compiler directives, core imperatives,
/// functional/pipeline, database, and HTTP/API categories.
///
/// The raw value of each case is its canonical pipe-gutter keyword (what appears in the DSL).
public enum CodeLogicStmtKind: String, Sendable, Equatable {

    // MARK: Control flow
    case `if`   = "if"
    case elseIf = "elseif"
    case `else` = "else"
    case `for`  = "for"
    case `while` = "while"
    case `try`  = "try"
    case `catch` = "catch"
    case `finally` = "finally"
    case `switch` = "switch"
    case `case` = "case"
    case `default` = "default"

    // MARK: Compiler directives
    case compilerIf    = "#if"
    case compilerElse  = "#else"
    case compilerEndIf = "#endif"

    // MARK: Core imperatives
    case call   = "call"
    case assign = "assign"
    case `return` = "return"
    case expr   = "expr"
    case raw    = "raw"

    // MARK: Functional / pipelines
    case pipe     = "pipe"
    case filter   = "filter"
    case select   = "select"
    case map      = "map"
    case reduce   = "reduce"
    case `let`    = "let"
    case match    = "match"
    case when     = "when"
    case endMatch = "endmatch"

    // MARK: Database
    case db        = "db"
    case `where`   = "where"
    case include   = "include"
    case orderBy   = "order-by"
    case skip      = "skip"
    case take      = "take"
    case toList    = "to-list"
    case first     = "first"
    case single    = "single"
    case dbInsert  = "db-insert"
    case dbUpdate  = "db-update"
    case dbDelete  = "db-delete"
    case set       = "set"
    case groupBy   = "group-by"
    case aggregate = "aggregate"
    case dbProcCall = "db-proc-call"
    case params    = "params"
    case sql       = "sql"
    case dbRaw     = "db-raw"

    // MARK: HTTP / API
    case http       = "http"
    case path       = "path"
    case query      = "query"
    case headers    = "headers"
    case auth       = "auth"
    case expect     = "expect"
    case body       = "body"
    case httpGraphQL = "http-graphql"
    case variables  = "variables"
    case grpc       = "grpc"
    case payload    = "payload"
    case metadata   = "metadata"
    case httpRaw    = "http-raw"
    case note       = "note"

    // MARK: Fallback
    case unknown = "unknown"

    /// Parses a keyword string (stripped of the trailing `>` and leading `|` depth markers)
    /// into a `LogicStatementKind`. Matching is case-insensitive.
    static func parse(_ keyword: String) -> CodeLogicStmtKind {
        Self(rawValue: keyword.lowercased()) ?? .unknown
    }

    /// The canonical pipe-gutter keyword string for this statement kind.
    public var keyword: String { rawValue }

    /// Whether this statement kind opens a scoped block whose body lines appear at depth+1.
    public var isBlock: Bool {
        switch self {
        case .`if`, .elseIf, .`else`,
             .`for`, .`while`,
             .`try`, .`catch`, .`finally`,
             .`switch`, .`case`, .`default`,
             .compilerIf, .compilerElse,
             .pipe, .filter, .select, .map, .reduce, .`let`,
             .match, .when,
             .db, .dbProcCall,
             .http, .path, .query, .headers, .body,
             .httpGraphQL, .variables,
             .grpc, .payload, .metadata,
             .params, .sql,
             .raw, .note:
            return true
        default:
            return false
        }
    }
}
