//
//  ExpressionEvaluator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ExpressionEvaluator {
    public func evaluate(value valueStr: String, pInfo: ParsedInfo) async throws -> Sendable? {
        let value = valueStr.trim()
        let ctx = pInfo.ctx
        
        //check if string literal
        if let match = value.wholeMatch(of: CommonRegEx.stringLiteralPattern_Capturing) {
            
            let (_, str, str2) = match.output
            return str ?? str2
        }
        
        //check if number(int, double) literal
        if let match = value.wholeMatch(of: CommonRegEx.numberLiteralPattern_Capturing) {
            
            let (_, int, dbl) = match.output
            return int ?? dbl ?? 0
        }
        
        //check if variable or object property
        if let _ = value.wholeMatch(of: CommonRegEx.variableOrObjectProperty) {
            if let value = try await ctx.valueOf(variableOrObjProp: value, with: pInfo) {
                return value
            }
        }
        
        if let bool = Bool(value) {
            return bool
        }
        
        return nil
    }
    
    public func evaluate(expression: String, pInfo: ParsedInfo) async throws -> Sendable? {
        let expn = expression.trim()
        let ctx = pInfo.ctx
        
        if await ctx.variables.has(expn) {
            return await ctx.variables[expn]
        }
        
        if let result = try await evaluate(value: expn, pInfo: pInfo) {
            return result
        }
        
        //As, it is not an object, assume it is an expression,
        //syntax: LHS operator RHS
        //LHS and RHS can be nested and can have paranthesis
        //nested paranthesis is not supported;
        //but single-level of paranthesis is allowed
        var parser: RegularExpressionEvaluator = RegularExpressionEvaluator()
        return try await parser.evaluate(expression: expn, pInfo: pInfo)
    }
    
    public func evaluateCondition(expression: String, pInfo: ParsedInfo) async throws -> Bool {
        if let result = try await evaluate(expression: expression, pInfo: pInfo) {
            return getEvaluatedBoolValueFor(result)
        } else {
            return false
        }
    }
    
    public func evaluateCondition(value: Optional<Any>, with ctx: Context) -> Bool {
        if let result = value {
            return getEvaluatedBoolValueFor(result)
        } else {
            return false
        }
    }
    
    fileprivate func getEvaluatedBoolValueFor(_ resultOptional: Any) -> Bool {
        //Special handling for nested optionals of 'Any', which can be problematic with nil values
        //This is needed because Swift's type system doesn't allow direct checking of nested optionals within 'Any', due to type erasure.
        guard let result = deepUnwrap(resultOptional) else { return false }

        switch type(of: result) {
        case is String.Type :
            if let str = result as? String {
                return str.trim().isNotEmpty
            } else {
                return false
            }
        case is Int.Type :
            if let integer = result as? Int {
                return integer != 0
            } else {
                return false
            }
        case is Double.Type :
            if let dbl = result as? Double {
                return dbl != 0
            } else {
                return false
            }
        case is Bool.Type :
            if let b = result as? Bool {
                return b
            } else {
                return false
            }
        case is Date.Type :
            if let d = result as? Date {
                return d.timeIntervalSince1970 > 0
            } else {
                return false
            }
        default: //if type is object
            return true
        }
    }
    
}



