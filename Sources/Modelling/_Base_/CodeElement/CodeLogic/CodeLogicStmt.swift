//
//  CodeLogicStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// A single node in a method's logic tree, corresponding to one pipe-gutter statement.
///
/// Statements at the same depth are siblings; statements at depth+1 immediately following
/// a block-capable statement become its `children`.
///
/// Example (depth 1 = top-level method body, depth 2 = inside a block):
/// ```
/// |if> amount > 0
/// ||return amount * discount
/// |else>
/// ||return 0
/// |call audit(orderId)
/// ```
public actor CodeLogicStmt {
    public var kind: CodeLogicStmtKind
    /// The expression or payload on the same line as the keyword (trimmed).
    public var expression: String
    /// Nested statements at the next depth level, collected while building the tree.
    public var children: [CodeLogicStmt]

    public init(kind: CodeLogicStmtKind, expression: String = "", children: [CodeLogicStmt] = []) {
        self.kind = kind
        self.expression = expression
        self.children = children
    }

    func setChildren(_ newChildren: [CodeLogicStmt]) {
        self.children = newChildren
    }
}
