//
//  ForStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct ForStmt: BlockTemplateStmt {
    public var state: BlockTemplateStmtState
    
    static let START_KEYWORD = "for"
    static let LOOP_VARIABLE = "@loop"

    public private(set) var ForVar: String = ""
    public private(set) var InArrayVar: String = ""
    
    nonisolated(unsafe)
    static let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variableOrObjectProperty
        } transform: { String($0) }
        OneOrMore(.whitespace)
        "in"
        OneOrMore(.whitespace)
        Capture {
            ChoiceOf{
                CommonRegEx.variable
                CommonRegEx.objectPropertyPattern
            }
        } transform: { String($0) }
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: Self.stmtRegex ) else { return false }

        let (_, forVar, inVar) = match.output
        self.ForVar = forVar
        self.InArrayVar = inVar
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard ForVar.isNotEmpty,
              InArrayVar.isNotEmpty,
              await children.count != 0 else { return nil }

        guard let loopItems = try await ctx.valueOf(variableOrObjProp: InArrayVar, with: pInfo) as? [Sendable] else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(InArrayVar, pInfo)
        }
        
        let loopVariableName = ForVar
        var rendering = ""

        await ctx.pushSnapshot()
        let loopWrap = ForLoop_Wrap(self)
        await ctx.variables.set(ForStmt.LOOP_VARIABLE, value: loopWrap)
        
        for (index, loopItem) in loopItems.enumerated() {
            await ctx.variables.set(loopVariableName, value: loopItem)
            await loopWrap.FIRST_IN_LOOP( index == loopItems.startIndex )
            await loopWrap.LAST_IN_LOOP( index == loopItems.index(before: loopItems.endIndex))
            
            if let body = try await children.execute(with: ctx) {
                rendering += body
            }
                
        }
        
        await ctx.popSnapshot()
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        get async {
            var str =  """
        FOR stmt (level: \(pInfo.level))
        - forVar: \(self.ForVar)
        - inVar: \(self.InArrayVar)
        - children:
        
        """
            await str += debugStringForChildren()
            
            return str
        }
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        state = BlockTemplateStmtState(keyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static let register = BlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in ForStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}
