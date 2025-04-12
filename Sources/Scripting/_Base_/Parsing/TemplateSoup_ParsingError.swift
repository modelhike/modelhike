//
//  TemplateSoup_ParsingError.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum TemplateSoup_ParsingError: ErrorWithMessageAndParsedInfo {
    case invalidFrontMatter(String, ParsedInfo)
    case invalidStmt(ParsedInfo)
    case invalidMultiBlockStmt(ParsedInfo)
    case invalidTemplateFunctionStmt(String, ParsedInfo)
    case objectNotFound(String, ParsedInfo)
    case objectTypeNotFound(String, ParsedInfo)
    case invalidPropertyNameUsedInCall(String, ParsedInfo)
    case modifierNotFound(String, ParsedInfo)
    case modifierInvalidSyntax(String, ParsedInfo)
    case modifierInvalidArguments(String, ParsedInfo)
    case modifierCalledOnwrongType(String, String, ParsedInfo)
    case invalidExpression(String, ParsedInfo)
    case invalidExpression_VariableOrObjPropNotFound(String, ParsedInfo)
    case invalidExpression_CustomMessage(String, ParsedInfo)
    case infixOperatorNotFound(String, ParsedInfo)
    case infixOperatorCalledOnwrongLhsType(String, String, ParsedInfo)
    case infixOperatorCalledOnwrongRhsType(String, String, ParsedInfo)
    case templateFunctionNotFound(String, ParsedInfo)

    public var info: String {
        let suffix = ""
        
        switch (self) {
        case .invalidFrontMatter(let line, _) :
            return suffix + "invalid front matter: \(line)"
        case .invalidStmt(let pInfo) :
            return suffix + "invalid stmt: \(pInfo.line)"
        case .invalidMultiBlockStmt(let pInfo) :
            return suffix + "invalid syntax:  \(pInfo.line)"
        case .invalidTemplateFunctionStmt(let line, _) :
            return suffix + "invalid fn definition: \(line)"
        case .objectNotFound(let obj, _) :
            return suffix + "object: \(obj) not found"
        case .objectTypeNotFound(let type, _) :
            return suffix + "object type: \(type) not found"
            
        case .modifierNotFound(let modifier, _) :
            return suffix + "modifier: \(modifier) not found"
        case .modifierInvalidSyntax(let modifier, _) :
            return suffix + "modifier - invalid syntax: \(modifier)"
        case .modifierInvalidArguments(let modifier, _) :
            return suffix + "Invalid modifier arguments : \(modifier)"
        case .modifierCalledOnwrongType(let modifier, let typeName, _) :
            return suffix + "modifier: '\(modifier)' called on wrong type:\(typeName)"

        case .infixOperatorNotFound(let infix, _) :
            return suffix + "infix operator: \(infix) not found"
        case .infixOperatorCalledOnwrongLhsType(let infix, let typeName, _) :
            return suffix + "operator: '\(infix)' called on wrong LHS type:\(typeName)"
        case .infixOperatorCalledOnwrongRhsType( let infix, let typeName, _) :
            return suffix + "operator: '\(infix)' called on wrong RHS type:\(typeName)"
        
        case .invalidExpression(let expn, _) :
            return suffix + "expression - invalid syntax: \(expn)"
        case .invalidExpression_VariableOrObjPropNotFound(let expn, _) :
            return suffix + "expression - value not found for: \(expn)"
        case .invalidExpression_CustomMessage(let msg, _) :
            return suffix + "expression - \(msg)"
            
        case .invalidPropertyNameUsedInCall(let propName, _) :
            return suffix + "Invalid prop : \(propName)"
        case .templateFunctionNotFound(let fnName, _) :
            return suffix + "fn: \(fnName) not found"
            
        }
    }

    public var pInfo: ParsedInfo {
        return switch self {
            case .invalidFrontMatter(_, let pInfo) : pInfo
            case .invalidStmt(let pInfo) : pInfo
            case .invalidMultiBlockStmt(let pInfo) : pInfo
            case .invalidTemplateFunctionStmt(_, let pInfo) : pInfo
            case .objectNotFound(_, let pInfo) : pInfo
            case .objectTypeNotFound(_, let pInfo) : pInfo

            case .modifierNotFound(_, let pInfo) : pInfo
            case .modifierInvalidSyntax(_, let pInfo) : pInfo
            case .modifierInvalidArguments(_, let pInfo) : pInfo
            case .modifierCalledOnwrongType(_, _, let pInfo) : pInfo

            case .infixOperatorNotFound(_, let pInfo) : pInfo
            case .infixOperatorCalledOnwrongLhsType(_, _, let pInfo) : pInfo
            case .infixOperatorCalledOnwrongRhsType(_, _, let pInfo) : pInfo
            
            case .invalidExpression(_, let pInfo) : pInfo
            case .invalidExpression_VariableOrObjPropNotFound(_, let pInfo) : pInfo
            case .invalidExpression_CustomMessage(_, let pInfo) : pInfo

            case .invalidPropertyNameUsedInCall(_, let pInfo) : pInfo
            case .templateFunctionNotFound(_, let pInfo) : pInfo
            
        }
    }
}
