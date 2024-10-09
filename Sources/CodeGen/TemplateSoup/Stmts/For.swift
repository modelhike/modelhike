//
// ForStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class ForStmt: BlockTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "for"
    static let FIRST_IN_LOOP = "_firstInLoop"
    static let LAST_IN_LOOP = "_lastInLoop"

    public private(set) var ForVar: String = ""
    public private(set) var InArrayVar: String = ""
    
    static let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variable
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
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
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

        guard let loopItems = try ctx.valueOf(variableOrObjProp: InArrayVar, lineNo: lineNo) as? [Any] else { return nil }
        
        let loopVariableName = ForVar
        var rendering = ""

        ctx.pushSnapshot()
        
        for (index, loopItem) in loopItems.enumerated() {
            ctx.variables[loopVariableName] = loopItem

            ctx.variables[Self.FIRST_IN_LOOP] = index == loopItems.startIndex
            ctx.variables[Self.LAST_IN_LOOP] = index == loopItems.index(before: loopItems.endIndex)
            
            if let body = try children.execute(with: ctx) {
                rendering += body
            }
                
        }
        
        ctx.popSnapshot()
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        var str =  """
        FOR stmt (level: \(level))
        - forVar: \(self.ForVar)
        - inVar: \(self.InArrayVar)
        - children:
        
        """
        
        str += debugStringForChildren()
        
        return str
    }
    
    public init(parseTill endKeyWord: String) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord)
    }
    
    static var register = BlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord in ForStmt(parseTill: endKeyWord)
    }
}
