//
// TemplateSoup_ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum TemplateSoup_ParsingError: Error, Equatable {
    case invalidFrontMatter(String)
    case invalidStmt(String)
    case invalidMultiBlockStmt(Int, String)
    case invalidTemplateFunctionStmt(String)
    case objectNotFound(String)
    case modifierNotFound(String)
    case modifierInvalidSyntax(String)
    case modifierInvalidArguments(String)
    case modifierCalledOnwrongType(String, String)
    case invalidExpression(Int, String)
    case infixOperatorNotFound(String)
    case infixOperatorCalledOnwrongLhsType(String, String)
    case infixOperatorCalledOnwrongRhsType(String, String)
    case templateFunctionNotFound(String)

    public var info: String {
        let suffix = ""
        
        switch (self) {
            case .invalidFrontMatter(let line) : 
                return suffix + "invalid front matter: \(line)"
            case .invalidStmt(let line) :
                return suffix + "invalid stmt: \(line)"
            case .invalidMultiBlockStmt(let lineNo, let line) :
                return suffix + "[Line \(lineNo) - Invalid syntax]  \(line)"
            case .invalidTemplateFunctionStmt(let line) :
                return suffix + "invalid fn definition: \(line)"
            case .objectNotFound(let obj) :
                return suffix + "object: \(obj) not found"
            case .modifierNotFound(let modifier) :
                return suffix + "modifier: \(modifier) not found"
            case .modifierInvalidSyntax(let modifier) :
                return suffix + "modifier - invalid syntax: \(modifier)"
            case .modifierInvalidArguments(let modifier) :
                return suffix + "Invalid modifier arguments : \(modifier)"
            case .modifierCalledOnwrongType(let modifier, let typeName) :
                return suffix + "modifier: '\(modifier)' called on wrong type:\(typeName)"

            case .infixOperatorNotFound(let infix) : 
                return suffix + "infix operator: \(infix) not found"
            case .infixOperatorCalledOnwrongLhsType(let infix, let typeName) : 
                return suffix + "operator: '\(infix)' called on wrong LHS type:\(typeName)"
            case .infixOperatorCalledOnwrongRhsType(let infix, let typeName) :
                return suffix + "operator: '\(infix)' called on wrong RHS type:\(typeName)"
            
            case .invalidExpression(_, let expn) :
                return suffix + "expression - invalid syntax: \(expn)"
            
            case .templateFunctionNotFound(let fnName) : 
                return suffix + "fn: \(fnName) not found"
            
        }
    }

}
