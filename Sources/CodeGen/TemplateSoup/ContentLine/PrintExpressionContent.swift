//
// PrintExpressionContent.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class PrintExpressionContent: ContentLineItem {
    var expression: String
    public let pInfo: ParsedInfo
    let level: Int
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
            throw TemplateSoup_ParsingError.invalidExpression(line, pInfo)
                            }

        let (_, expn, modifiersList) = match.output
        self.expression = expn
        self.ModifiersList = try Modifiers.parse(string: modifiersList, pInfo: pInfo)

    }
    
    public func execute(with ctx: Context) throws -> String? {
        
        if let body = try ctx.evaluate(expression: expression, with: pInfo) ,
           let modifiedBody = try Modifiers.apply(to: body, modifiers: self.ModifiersList, pInfo: pInfo) {
            //if string, return it as-such; else convert to string
            if let result = modifiedBody as? String {
                return result
            } else {
                return String(describing: modifiedBody)
            }
        } else {
            throw TemplateSoup_ParsingError.invalidExpression(expression, pInfo)
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
    
    public init(expressionLine: String, pInfo: ParsedInfo, level: Int) throws {
        self.expression = ""
        self.pInfo = pInfo
        self.level = level

        try self.parseLine(expressionLine.trim())
    }
}
