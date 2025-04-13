//
//  CreateOperator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct CreateOperator {
    public static func infix<A, B, T: Sendable>(_ name: String, body: @Sendable @escaping (A, B) -> T)
        -> InfixOperatorProtocol
    {
        return InfixOperator(name: name, handler: body)
    }

    public static func prefix<A, T>(_ name: String, body: @Sendable @escaping (A) -> T) -> Operator {
        return PrefixOperator(name: name, handler: body)
    }

    public static func suffix<A, T>(_ name: String, body: @Sendable @escaping (A) -> T) -> Operator {
        return SuffixOperator(name: name, handler: body)
    }
}
