//
//  ModifierInstance.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ModifierInstanceWithoutArgs<I, T: Sendable> : ModifierInstanceWithoutArgsProtocol {
    public let name : String
    private let callerType: Any.Type
    private let handler: @Sendable (I, ParsedInfo) throws  -> T?
    
    public func applyTo(value : Sendable, with pInfo: ParsedInfo) throws -> Sendable {
        
        if let typedValue = value as? I {
            if type(of: typedValue) != self.callerType {
                throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)), pInfo)
            }
            
            return try handler(typedValue, pInfo)
        } else {
            throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)), pInfo)
        }
    }
    
    public init(name: String, handler: @escaping @Sendable (I, ParsedInfo) throws -> T?) {
        self.name = name
        self.callerType = I.self
        self.handler = handler
    }
}

public struct ModifierInstanceWithUnNamedArgs<I, T: Sendable> : ModifierInstanceWithUnNamedArgsProtocol {
    public var name : String
    public let callerType: Any.Type
    private let handler: @Sendable (I, [Any], ParsedInfo) throws -> T?
    private var arguments: [String] = []
    
    public mutating func setArgsGiven(arguments: [String]) {
        self.arguments = arguments
    }
    
    public func applyTo(value : Sendable, with pInfo: ParsedInfo) async throws -> Sendable {
        
        if let typedValue = value as? I {
            if type(of: typedValue) != self.callerType {
                throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)), pInfo)
            }
            
            var argumentValues: [Any] = []
            
            for argument in arguments {
                if let argValue = try await pInfo.ctx.evaluate(expression: argument, with: pInfo) {
                    argumentValues.append(argValue)
                } else {
                    //argumentValues.append(Optional<Any>.none as Any)
                    throw TemplateSoup_ParsingError.modifierInvalidArguments(self.name, pInfo)
                }
            }
            
            return try handler(typedValue, argumentValues, pInfo)
        } else {
            throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)), pInfo)
        }
    }
    
    public init(name: String, handler: @escaping @Sendable (I, [Any], ParsedInfo) throws -> T?) {
        self.name = name
        self.callerType = I.self
        self.handler = handler
    }
}

public protocol ModifierInstanceWithoutArgsProtocol : ModifierInstance {
}

public protocol ModifierInstanceWithUnNamedArgsProtocol : ModifierInstanceWithArgsProtocol {
    mutating func setArgsGiven(arguments: [String])
}

public protocol ModifierInstanceWithArgsProtocol : ModifierInstance {
}

public protocol ModifierInstance: Sendable {
    var name : String {get}
    //var callerType: Any.Type {get}
    func applyTo(value : Sendable, with pInfo: ParsedInfo) async throws -> Sendable
}
