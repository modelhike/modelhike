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
    case objectNotFound(String)
    case modifierNotFound(String)
    case modifierInvalidSyntax(String)
    case modifierCalledOnwrongType(String, String)
    case invalidExpression(Int, String)
    case infixOperatorNotFound(String)
    case infixOperatorCalledOnwrongLhsType(String, String)
    case infixOperatorCalledOnwrongRhsType(String, String)
    case macroFunctionNotFound(String)

    public var info: String { 
        switch (self) {
            case .invalidFrontMatter(let line) : return "front matter: \(line) is invalid"
            case .invalidStmt(let line) : return "stmt: \(line) is invalid"
            case .invalidMultiBlockStmt(let lineNo, let line) :
            return """
                [Line \(lineNo) - Invalid syntax]  \(line)
                """
            
            case .objectNotFound(let obj) : return "object: \(obj) not found"
            case .modifierNotFound(let modifier) : return "modifier: \(modifier) not found"
            case .modifierInvalidSyntax(let modifier) : return "modifier: \(modifier) invalid syntax"
            case .modifierCalledOnwrongType(let modifier, let typeName) : return "modifier: '\(modifier)' called on wrong type:\(typeName)"
            
            case .infixOperatorNotFound(let infix) : return "infix operator: \(infix) not found"
            case .infixOperatorCalledOnwrongLhsType(let infix, let typeName) : return "operator: '\(infix)' called on wrong LHS type:\(typeName)"
            case .infixOperatorCalledOnwrongRhsType(let infix, let typeName) : return "operator: '\(infix)' called on wrong RHS type:\(typeName)"
            
            case .invalidExpression(_, let expn) : return "expression: \(expn) invalid syntax"
            
            case .macroFunctionNotFound(let fnName) : return "macro fn: \(fnName) not found"
            
        }
    }

}
