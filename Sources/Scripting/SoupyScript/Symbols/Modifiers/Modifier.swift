//
//  Modifier.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ModifierWithoutArgs<I, T> : ModifierWithoutArgsProtocol {
    public let name : String
    private let handler: (I, ParsedInfo) throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithoutArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping (I, ParsedInfo) throws -> T?) {
        self.name = name
        self.handler = handler
    }
}

public struct ModifierWithUnNamedArgs<I, T> : ModifierWithUnNamedArgsProtocol {
    public let name : String
    private let handler: (I, [Any], ParsedInfo) throws -> T?
    
    public func instance() -> ModifierInstance {
        ModifierInstanceWithUnNamedArgs(name: name, handler: handler)
    }
    
    public init(name: String, handler: @escaping (I, [Any], ParsedInfo) throws -> T?) {
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
