//
// Operator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct InfixOperator<A, B, T> : InfixOperatorProtocol {
    public var name : String
    private let lhsType: A.Type
    private let rhsType: B.Type
    private let handler: (A, B) -> T
    public var kind : OperatorKind { .infix }

    public func applyTo(lhs : Optional<Any>, rhs: Optional<Any>, pInfo: ParsedInfo) throws -> Any {
        guard let typedLhs = lhs as? A else {
            throw TemplateSoup_ParsingError.infixOperatorCalledOnwrongLhsType(self.name, String(describing: type(of: lhs)), pInfo)
        }
        
        if type(of: typedLhs) != self.lhsType {
            throw TemplateSoup_ParsingError.infixOperatorCalledOnwrongLhsType(self.name, String(describing: type(of: typedLhs)), pInfo)
        }
        
        guard let typedRhs = rhs as? B else {
            throw TemplateSoup_ParsingError.infixOperatorCalledOnwrongRhsType(self.name, String(describing: type(of: rhs)), pInfo)
        }
        
        if type(of: typedRhs) != self.rhsType {
            throw TemplateSoup_ParsingError.infixOperatorCalledOnwrongRhsType(self.name, String(describing: type(of: typedRhs)), pInfo)
        }
            
        return handler(typedLhs, typedRhs)
    }
    
    public init(name: String, handler: @escaping (A, B) -> T) {
        self.name = name
        self.lhsType = A.self
        self.rhsType = B.self
        self.handler = handler
    }
}

public struct SuffixOperator<A, T> : Operator {
    public var name : String
    public var callerType: A.Type
    private var handler: (A) -> T
    
    public var kind : OperatorKind { .infix }

    public init(name: String, handler: @escaping (A) -> T) {
        self.name = name
        self.callerType = A.self
        self.handler = handler
    }
}

public struct PrefixOperator<A, T> : Operator {
    public var name : String
    public var callerType: A.Type
    private var handler: (A) -> T
    
    public var kind : OperatorKind { .infix }

    public init(name: String, handler: @escaping (A) -> T) {
        self.name = name
        self.callerType = A.self
        self.handler = handler
    }
}

public protocol InfixOperatorProtocol : Operator {
    func applyTo(lhs : Optional<Any>, rhs: Optional<Any>, pInfo: ParsedInfo) throws -> Any
}

public protocol Operator {
    var name : String {get set}
    var kind : OperatorKind {get}
}

public enum OperatorKind {
    case infix, suffix, prefix
}
