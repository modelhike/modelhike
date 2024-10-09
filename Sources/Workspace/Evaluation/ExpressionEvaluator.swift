//
// ExpressionEvaluator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ExpressionEvaluator {
    public func evaluate(value valueStr: String, lineNo: Int, with ctx: Context) throws -> Optional<Any> {
        let value = valueStr.trim()
        
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
            if let value = try ctx.valueOf(variableOrObjProp: value, lineNo: lineNo) {
                return value
            }
        }
        
        if let bool = Bool(value) {
            return bool
        }
        
        return nil
    }
    
    public func evaluate(expression: String, lineNo: Int, with ctx: Context) throws -> Optional<Any> {
        let expn = expression.trim()
        
        if ctx.variables.has(expn) {
            return ctx.variables[expn]
        }
        
        if let result = try evaluate(value: expn, lineNo: lineNo, with: ctx) {
            return result
        }
        
        //As, it is not an object, assume it is an expression,
        //syntax: LHS operator RHS
        //LHS and RHS can be nested and can have paranthesis
        //nested paranthesis is not supported;
        //but single-level of paranthesis is allowed
        var parser: RegularExpressionEvaluator = RegularExpressionEvaluator()
        return try parser.evaluate(expression: expn, lineNo: lineNo, with: ctx)
    }
    
    public func evaluateCondition(expression: String, lineNo: Int, with ctx: Context) throws -> Bool {
        if let result = try evaluate(expression: expression, lineNo: lineNo, with: ctx) {
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



