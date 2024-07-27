//
// ModifierInstance.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ModifierInstanceWithoutArgs<I, T> : ModifierInstanceWithoutArgsProtocol {
    public let name : String
    private let callerType: Any.Type
    private let handler: (I, Int) -> T?
    
    public func applyTo(value : Any, lineNo: Int, with ctx: Context) throws -> Any {
        
        if let typedValue = value as? I {
            if type(of: typedValue) != self.callerType {
                throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)))
            }
            
            return handler(typedValue, lineNo) as Any
        } else {
            throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)))
        }
    }
    
    public init(name: String, handler: @escaping (I, Int) -> T?) {
        self.name = name
        self.callerType = I.self
        self.handler = handler
    }
}

public struct ModifierInstanceWithUnNamedArgs<I, T> : ModifierInstanceWithUnNamedArgsProtocol {
    public var name : String
    public let callerType: Any.Type
    private let handler: (I, [Any], Int) -> T?
    private var arguments: [String] = []
    
    public mutating func setArgsGiven(arguments: [String]) {
        self.arguments = arguments
    }
    
    public func applyTo(value : Any, lineNo: Int, with ctx: Context) throws -> Any {
        
        if let typedValue = value as? I {
            if type(of: typedValue) != self.callerType {
                throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)))
            }
            
            var argumentValues: [Any] = []
            
            for argument in arguments {
                if let argValue = try ctx.evaluate(expression: argument, lineNo: lineNo) {
                    argumentValues.append(argValue)
                } else {
                    argumentValues.append(Optional<Any>.none as Any)
                }
            }
            
            return handler(typedValue, argumentValues, lineNo) as Any
        } else {
            throw TemplateSoup_ParsingError.modifierCalledOnwrongType(self.name, String(describing: type(of: value)))
        }
    }
    
    public init(name: String, handler: @escaping (I, [Any], Int) -> T?) {
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

public protocol ModifierInstance {
    var name : String {get}
    //var callerType: Any.Type {get}
    func applyTo(value : Any, lineNo: Int, with ctx: Context) throws -> Any
}
