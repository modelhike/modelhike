//
//  CodeLogic.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// The structured logic body of a method, expressed as a tree of pipe-gutter statements.
///
/// A `CodeLogic` is attached to a `MethodObject` when the method has inline logic
/// declared in the `.modelhike` DSL using the `|`-prefixed pipe-gutter syntax.
///
/// The `statements` array holds the top-level nodes (depth 1). Each node may have
/// `children` at the next depth level, building an arbitrarily deep tree.
///
/// Example DSL (inside a class body after a `~` method declaration):
/// ```
/// ~ processOrder(orderId: Id) : Order
/// |> DB Orders
/// | |> WHERE o -> o.id == orderId
/// | |> FIRST
/// | |> LET order = _
/// |> IF order.status == "PENDING"
/// | assign order.status = "PROCESSING"
/// | |> DB-UPDATE Orders -> o.id == orderId
/// | | |> SET status = order.status
/// |> RETURN order
/// ```
public struct CodeLogic: Sendable {
    public var statements: [CodeLogicStmt]

    public var isEmpty: Bool { statements.isEmpty }

    public init(statements: [CodeLogicStmt] = []) {
        self.statements = statements
    }
}
