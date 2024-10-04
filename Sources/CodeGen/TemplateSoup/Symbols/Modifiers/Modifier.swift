//
// Modifier.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ModifierWithoutArgs<I, T> : ModifierWithoutArgsProtocol {
    public let name : String
    private let handler: (I, Int) throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithoutArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping (I, Int) throws -> T?) {
        self.name = name
        self.handler = handler
    }
}

public struct ModifierWithUnNamedArgs<I, T> : ModifierWithUnNamedArgsProtocol {
    public let name : String
    private let handler: (I, [Any], Int) throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithUnNamedArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping (I, [Any], Int) throws -> T?) {
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

public protocol Modifier {
    var name : String {get}
    func instance() -> ModifierInstance
}
