//
//  ResultBuilder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

@resultBuilder
public struct ResultBuilder<T>: Sendable {
    // Corresponding to the case where no component is used in the block
    @inlinable
    public static func buildBlock() ->  [T] {
        []
    }
    
    @inlinable
    public static func buildBlock(_ components: T...) -> [T] {
        return components
    }
    
    @inlinable
    public static func buildBlock(_ components: [T]...) -> [T] {
        return components.flatMap { $0 }
    }

    @inlinable
    public static func buildOptional(_ component: [T]?) -> [T] {
        return component ?? []
    }
    
    @inlinable
    public static func buildEither(first component: [T]) -> [T] {
        return component
    }
    
    @inlinable
    public static func buildEither(second component: [T]) -> [T] {
        return component
    }
    
    @inlinable
    public static func buildExpression(_ expression: T) -> [T] {
        return [expression]
    }

    @inlinable
    public static func buildExpression(_ expression: [T]) -> [T] {
        return expression
    }
    
    @inlinable
    public static func buildArray(_ components: [[T]]) -> [T] {
        return components.flatMap { $0 }
    }
    
    /// Add support for #availability checks.
    @inlinable
    public static func buildLimitedAvailability(_ components: [T]) -> [T] {
        components
    }
    
}

//public struct ResultNodeCollection<T> : Sequence {
//    var elements: [T]
//    
//    init(_ items: [T]) {
//        self.elements = items
//    }
//
//    public init<S: Sequence>(_ sequence: S) where S.Element == T {
//        self.elements = sequence.compactMap{ $0 }
//    }
//    
//    public func makeIterator() -> IndexingIterator<[T]> {
//        elements.makeIterator()
//    }
//
//}
