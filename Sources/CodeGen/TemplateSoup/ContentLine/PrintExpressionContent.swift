//
//  PrintExpressionContent.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct PrintExpressionContent: ContentLineItem {
    var expression: String
    public let pInfo: ParsedInfo
    let level: Int
    var ModifiersList: [ModifierInstance] = []

    nonisolated(unsafe)
    let expressionRegex = Regex {
        ZeroOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
    }
    
    fileprivate mutating func parseLine(_ line: String) async throws {
        guard let match = line.wholeMatch(of: expressionRegex )
                            else {
            throw TemplateSoup_ParsingError.invalidExpression(line, pInfo)
                            }

        let (_, expn, modifiersList) = match.output
        self.expression = expn
        self.ModifiersList = try await Modifiers.parse(string: modifiersList, pInfo: pInfo)

    }
    
    public func execute(with ctx: Context) async throws -> String? {
        
        if let body = try await ctx.evaluate(expression: expression, with: pInfo) ,
           let modifiedBody = try await Modifiers.apply(to: body, modifiers: self.ModifiersList, with: pInfo) {
            //if string, return it as-such; else convert to string
            if let result = modifiedBody as? String {
                return result
            } else {
                return String(describing: modifiedBody)
            }
        } else {
            //if expression is printing a single variable or object value
            if expression.isPattern(CommonRegEx.variableOrObjectProperty) {
                throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(expression, pInfo)
            } else {
                throw TemplateSoup_ParsingError.invalidExpression(expression, pInfo)
            }
        }
    }
    
    public var debugDescription: String {
            let str =  """
            EXPRESSION (level: \(level))
            - valueExpr: \(self.expression)
            - modifiers: \(self.ModifiersList.nameString())

            """
            
            return str
    }
    
    public init(expressionLine: String, pInfo: ParsedInfo, level: Int) async throws {
        self.expression = ""
        self.pInfo = pInfo
        self.level = level

        try await self.parseLine(expressionLine.trim())
    }
}
