//
// PrintExpressionContent.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class PrintExpressionContent: ContentLineItem {
    var expression: String
    let lineNo: Int
    let level: Int
    let ctx: Context
    var ModifiersList: [ModifierInstance] = []

    let expressionRegex = Regex {
        ZeroOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
    }
    
    fileprivate func parseLine(_ line: String) throws {
        guard let match = line.wholeMatch(of: expressionRegex )
                            else {
            throw TemplateSoup_ParsingError.invalidExpression(lineNo, line)
                            }

        let (_, expn, modifiersList) = match.output
        self.expression = expn
        self.ModifiersList = try Modifiers.parse(string: modifiersList, context: ctx)

    }
    
    public func execute(with ctx: Context) throws -> String? {
        
        if let body = try ctx.evaluate(expression: expression, lineNo: lineNo) ,
           let modifiedBody = try Modifiers.apply(to: body, modifiers: self.ModifiersList, lineNo: lineNo, with: ctx) {
            //if string, return it as-such; else convert to string
            if let result = modifiedBody as? String {
                return result
            } else {
                return String(describing: modifiedBody)
            }
        } else {
            throw TemplateSoup_ParsingError.invalidExpression(lineNo, expression)
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
    
    public init(expressionLine: String, lineNo: Int, level: Int, with ctx: Context) throws {
        self.expression = ""
        self.lineNo = lineNo
        self.level = level
        self.ctx = ctx

        try self.parseLine(expressionLine.trim())
    }
}
