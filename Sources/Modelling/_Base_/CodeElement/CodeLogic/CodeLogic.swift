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
/// |db> Orders
/// |where> o -> o.id == orderId
/// |first>
/// |let> order = _
/// |if> order.status == "PENDING"
/// ||assign order.status = "PROCESSING"
/// ||db-update> Orders -> o.id == orderId
/// |||set> status = order.status
/// |return order
/// ```
public struct CodeLogic: Sendable {
    public var statements: [CodeLogicStmt]

    public var isEmpty: Bool { statements.isEmpty }

    public init(statements: [CodeLogicStmt] = []) {
        self.statements = statements
    }
}
