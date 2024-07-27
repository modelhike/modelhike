//
// ResultBuilder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

@resultBuilder
public struct ResultBuilder<T> {
    // Corresponding to the case where no component is used in the block
    public static func buildBlock() ->  [T] {
        []
    }
    
    public static func buildBlock(_ components: T...) -> [T] {
        return components
    }
    
    public static func buildBlock(_ components: [T]...) -> [T] {
        return components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [T]?) -> [T] {
        return component ?? []
    }
    
    public static func buildEither(first component: [T]) -> [T] {
        return component
    }
    
    public static func buildEither(second component: [T]) -> [T] {
        return component
    }
    
    public static func buildExpression(_ expression: T) -> [T] {
        return [expression]
    }

    public static func buildExpression(_ expression: [T]) -> [T] {
        return expression
    }
    
    public static func buildArray(_ components: [[T]]) -> [T] {
        return components.flatMap { $0 }
    }
    
    /// Add support for #availability checks.
    public static func buildLimitedAvailability(_ components: [T]) -> [T] {
        components
    }
    
}
