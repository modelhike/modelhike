//
// SetVarStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class SetVarStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "set"

    public private(set) var SetVar: String = ""
    public private(set) var ValueExpression: String = ""
    public private(set) var ModifiersList: [ModifierInstance] = []
    
    let setVarLineRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variableOrObjectProperty
        } transform: { String($0) }
        OneOrMore(.whitespace)
        
        "="
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: setVarLineRegex )
                                                                else { return false }
        
        let (_, setVar, value, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = value
        self.ModifiersList = try Modifiers.parse(string: modifiersList, pInfo: pInfo)

        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        var actualBody: Any? = nil
        
        guard SetVar.isNotEmpty,
              ValueExpression.isNotEmpty else { return nil }
        
        if let body = try ctx.evaluate(expression: ValueExpression, with: pInfo) {
            let modifiedBody = try Modifiers.apply(to: body, modifiers: self.ModifiersList, with: pInfo)
            actualBody = modifiedBody
        }
            
        let variableName = self.SetVar

        if actualBody != nil {
            //special handling for setting current working directory
            if ctx.isWorkingDirectoryVariable(variableName) {
                if let str = actualBody as? String {
                    ctx.debugLog.workingDirectoryChanged(str)
                    ctx.variables[variableName] = str
                }
            } else {
                try ctx.setValueOf(variableOrObjProp: variableName, value: actualBody, with: pInfo)
            }
        } else {
            
            //special handling for setting current working directory
            if ctx.isWorkingDirectoryVariable(variableName) {
                //reset to base path
                ctx.debugLog.workingDirectoryChanged("(base path)")
                ctx.variables[variableName] = ""
            } else {
                try ctx.setValueOf(variableOrObjProp: variableName, value: nil, with: pInfo)
            }
        }
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        SET VAR Line stmt (level: \(pInfo.level))
        - setVar: \(self.SetVar)
        - valueExpr: \(self.ValueExpression)
        - modifiers: \(self.ModifiersList.nameString())

        """
        
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in SetVarStmt(pInfo)}
}

