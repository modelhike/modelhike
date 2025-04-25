//
//  Modifier.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ModifierWithoutArgs<I, T: Sendable> : ModifierWithoutArgsProtocol {
    public let name : String
    private let handler: @Sendable (I, ParsedInfo) async throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithoutArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping @Sendable (I, ParsedInfo) async throws -> T?) {
        self.name = name
        self.handler = handler
    }
}

public struct ModifierWithUnNamedArgs<I, T: Sendable> : ModifierWithUnNamedArgsProtocol {
    public let name : String
    private let handler: @Sendable (I, [Sendable], ParsedInfo) async throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithUnNamedArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping @Sendable (I, [Sendable], ParsedInfo) async throws -> T?) {
        self.name = name
        self.handler = handler
    }
}

public protocol ModifierWithoutArgsProtocol : Modifier {
    
}

public protocol ModifierWithUnNamedArgsProtocol : ModifierWithArgsProtocol {
}

public protocol ModifierWithArgsProtocol : Modifier {
}

public protocol Modifier: Sendable {
    var name : String {get}
    func instance() -> ModifierInstance
}
