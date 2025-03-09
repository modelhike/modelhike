//
//  ForStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class ForStmt: BlockTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "for"
    static let LOOP_VARIABLE = "@loop"

    public private(set) var ForVar: String = ""
    public private(set) var InArrayVar: String = ""
    
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
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: Self.stmtRegex ) else { return false }

        let (_, forVar, inVar) = match.output
        self.ForVar = forVar
        self.InArrayVar = inVar
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard ForVar.isNotEmpty,
              InArrayVar.isNotEmpty,
              children.count != 0 else { return nil }

        guard let loopItems = try ctx.valueOf(variableOrObjProp: InArrayVar, with: pInfo) as? [Any] else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(InArrayVar, pInfo)
        }
        
        let loopVariableName = ForVar
        var rendering = ""

        ctx.pushSnapshot()
        var loopWrap = ForLoop_Wrap(self)
        ctx.variables[ForStmt.LOOP_VARIABLE] = loopWrap
        
        for (index, loopItem) in loopItems.enumerated() {
            ctx.variables[loopVariableName] = loopItem

            loopWrap.FIRST_IN_LOOP = index == loopItems.startIndex
            loopWrap.LAST_IN_LOOP = index == loopItems.index(before: loopItems.endIndex)
            
            if let body = try children.execute(with: ctx) {
                rendering += body
            }
                
        }
        
        ctx.popSnapshot()
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        var str =  """
        FOR stmt (level: \(pInfo.level))
        - forVar: \(self.ForVar)
        - inVar: \(self.InArrayVar)
        - children:
        
        """
        
        str += debugStringForChildren()
        
        return str
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static var register = BlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in ForStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}
