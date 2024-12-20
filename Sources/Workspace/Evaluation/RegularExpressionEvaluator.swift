//
// RegexExpressionEvaluator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public struct RegularExpressionEvaluator {
    public mutating func evaluate(expression: String, pInfo: ParsedInfo) throws -> Optional<Any> {
        let ctx = pInfo.ctx
        
        var negatedResult = false
        
        var expressionToParse = expression
        if let firstWord = expression.firstWord(), firstWord == "not" {
            negatedResult = true
            expressionToParse = expressionToParse.remainingLine(after: firstWord)
        }
        
        var parsedArrList = try parseAsArray(expression: expressionToParse, pInfo: pInfo)
        //print(parsedArrList)

        //there is some expression given, but there is no parsed output
        //which means that something is wrong
        if parsedArrList.count == 0 && expression.trim().isNotEmpty {
            throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
        }
        
        guard parsedArrList.count != 0 else { return nil }
        
        var lhsArray = parsedArrList.removeFirst()
        var accumulated = try executeArrayItems(&lhsArray, expression, pInfo: pInfo)
        
        while parsedArrList.count > 0 {
            //in the parsed array list, every even item is an operator,
            //which will be a single item in an array
            guard let op = parsedArrList.removeFirst().first else {
                throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
            }
            
            var rhsArray = parsedArrList.removeFirst()
            
            guard let rhsResult = try executeArrayItems(&rhsArray, expression, pInfo: pInfo) else {
                throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
            }
            
            guard let infix = ctx.symbols.template.infixOperators.first(where: { $0.name == op }) else {
                throw TemplateSoup_ParsingError.infixOperatorNotFound(op, pInfo)
            }
                 
            accumulated = try infix.applyTo(lhs: accumulated, rhs: rhsResult, pInfo: pInfo)
        }
        
        guard let accumulated = accumulated else { return nil }
        
        let result = ctx.evaluateCondition(value: accumulated, pInfo: pInfo)
        return negatedResult ? !result : result
    }
    
    fileprivate func executeArrayItems(_ arr: inout [String], _ expression: String, pInfo: ParsedInfo) throws -> Optional<Any> {
        guard arr.count > 0 else { return nil }

        let ctx = pInfo.ctx        
        let lhs = arr.removeFirst()
        
        guard var result = try ctx.evaluate(value: lhs, pInfo: pInfo) else { return nil }
        
        while arr.count > 0 {
            //in the parsed array list, every even item is an operator
            let op = arr.removeFirst()
            
            guard arr.count > 0 else {
                throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
            }
            
            let rhs = arr.removeFirst()
            
            guard let rhsResult = try ctx.evaluate(value: rhs, pInfo: pInfo) else {
                throw TemplateSoup_EvaluationError.objectNotFound(rhs, pInfo)
            }
            
            guard let infix = ctx.symbols.template.infixOperators.first(where: { $0.name == op }) else {
                throw TemplateSoup_ParsingError.infixOperatorNotFound(op, pInfo)
            }
                
            result = try infix.applyTo(lhs: result, rhs: rhsResult, pInfo: pInfo)
                
        }
        
        return result
    }

    let regex = Regex {
        ZeroOrMore(.whitespace)
        
        Optionally{
            Capture {
                "("
            } transform: { String($0) }
        }
        
        ZeroOrMore(.whitespace)
        
            Capture {
                OneOrMore {
                    NegativeLookahead {
                        ")"
                    }
                    CharacterClass.whitespace.inverted
                }
            } transform: { String($0) }
        
        ZeroOrMore(.whitespace)
        
        Optionally{
            Capture {
                ")"
            } transform: { String($0) }
        }

        ZeroOrMore(.whitespace)
    }
    
    fileprivate var outer:[[String]] = []
    fileprivate var inner:[String] = []
    fileprivate var paranthesisStarted = false
    
    fileprivate mutating func parseAsArray(expression: String, pInfo: ParsedInfo) throws -> [[String]] {
        outer = []
        inner = []
        paranthesisStarted = false
        
        let matches = expression.matches(of: regex)
        for match in matches {
            let (_, openParan, part, closeParan) = match.output
            
            if let _ = openParan { //open paranthesis present
                if !paranthesisStarted {
                    paranthesisStarted = true
                    
                    if inner.count > 0 {
                        outer.append(inner)
                        inner = []
                    }
                } else {
                    throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
                }
            }
            
            
            inner.append(part)
            
            if let _ = closeParan { //close paranthesis present
                if paranthesisStarted {
                    paranthesisStarted = false
                    
                    if inner.count > 0 {
                        outer.append(inner)
                        inner = []
                    }
                } else {
                    throw TemplateSoup_EvaluationError.errorInExpression(expression, pInfo)
                }
            }

        }

        if inner.count > 0 {
            outer.append(inner)
        }
        
        //till now array will be split as per scope
        //E.g. var1 and (var2 and var3) and var4 or var5
        //will be split into
        // item 0 - var1, and
        // item 1 - var2, or, var3
        // item 2 - and, var4, or, var5
        // NOW, the operators which join two score are to be split into another single array
        //i.e, operators at the end of item 0 and at the start of item 2 are to be split
        //expected:
        // item 0 - var1
        // item 1 - and
        // item 2 - var2, or, var3
        // item 3 - and
        // item 4 - var4, or, var5
        
        let ctx = pInfo.ctx
        var newOuter: [[String]] = []
        
        var i = 0
        while i < outer.count {
            var inner = outer[i]
            
            //arrays having extra operator at start/end will be having even count
            if inner.count % 2 == 0 {
                //check if the first item of the inner is an operator
                if let op = inner.first {
                    if let _ = ctx.symbols.template.infixOperators.first(where: { $0.name == op }) {
                        inner.removeFirst()
                        
                        newOuter.append([op])
                        newOuter.append(inner)
                        
                        i += 1
                        continue
                    }
                }
                
                //check if the last item of the inner is an operator
                if let op = inner.last {
                    if let _ = ctx.symbols.template.infixOperators.first(where: { $0.name == op }) {
                        inner.removeLast()
                        
                        newOuter.append(inner)
                        newOuter.append([op])
                        
                        i += 1
                        continue
                    }
                }
                
                throw TemplateSoup_ParsingError.invalidExpression(expression, pInfo)
            } else {
                newOuter.append(inner)
            }
            
            i += 1
        }
        
        return newOuter
    }
    
    public init() {
        
    }
}
