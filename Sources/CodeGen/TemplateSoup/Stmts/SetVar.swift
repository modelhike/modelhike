//
// SetVarStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class SetVarStmt: BlockOrLineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "set"

    public private(set) var SetVar: String = ""
    public private(set) var ValueExpression: String = ""
    public private(set) var ModifiersList: [ModifierInstance] = []

    let setVarBlockRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variable
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
        
        CommonRegEx.comments
    }
    
    let setVarLineRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variable
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
    
    override func checkIfLineVariant(line: String) -> Bool {
        let match = line.wholeMatch(of: setVarLineRegex )
        return match != nil
    }

    override func matchLine_BlockVariant(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: setVarBlockRegex )
                                                                else { return false }

        let (_, setVar, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = ""
        self.ModifiersList = try Modifiers.parse(string: modifiersList, context: pInfo.ctx)

        return true
    }
    
    override func matchLine_LineVariant(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: setVarLineRegex )
                                                                else { return false }
        
        let (_, setVar, value, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = value
        self.ModifiersList = try Modifiers.parse(string: modifiersList, context: pInfo.ctx)

        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        if isBlockVariant {
            guard SetVar.isNotEmpty,
                  children.count != 0 else { return nil }
            
            let variableName = self.SetVar

            if let body = try children.execute(with: ctx) {
                let modifiedBody = try Modifiers.apply(to: body.trim(), modifiers: self.ModifiersList, pInfo: pInfo)
                
                //special handling for setting current working directory
                if ctx.isWorkingDirectoryVariable(variableName) {
                    if let str = modifiedBody as? String {
                        ctx.debugLog.workingDirectoryChanged(str)
                        ctx.variables[variableName] = str
                    }
                } else {
                    ctx.variables[variableName] = modifiedBody
                }
            } else {
                
                //special handling for setting current working directory
                if ctx.isWorkingDirectoryVariable(variableName) {
                    //reset to base path
                    ctx.variables[variableName] = ""
                } else {
                    ctx.variables[variableName] = ""
                }
            }
                
        } else {
            guard SetVar.isNotEmpty,
                  ValueExpression.isNotEmpty else { return nil }
            
            let variableName = self.SetVar

            if let body = try ctx.evaluate(expression: ValueExpression, pInfo: pInfo) {
                    let modifiedBody = try Modifiers.apply(to: body, modifiers: self.ModifiersList, pInfo: pInfo)
                    
                    //special handling for setting current working directory
                    if ctx.isWorkingDirectoryVariable(variableName) {
                        if let str = modifiedBody as? String {
                            ctx.debugLog.workingDirectoryChanged(str)
                            ctx.variables[variableName] = str
                        }
                    } else {
                        ctx.variables[variableName] = modifiedBody
                    }
                
            } else {
                
                //special handling for setting current working directory
                if ctx.isWorkingDirectoryVariable(variableName) {
                    //reset to base path
                    ctx.variables[variableName] = ""
                } else {
                    ctx.variables[variableName] = nil
                }
            }
        }
        
        return nil
    }
    
    public var debugDescription: String {
        if self.isBlockVariant {
            var str =  """
            SET VAR Block stmt (level: \(pInfo.level))
            - setVar: \(self.SetVar)
            - modifiers: \(self.ModifiersList.nameString())
            - children:
            
            """
            
            str += debugStringForChildren()
            
            return str

        } else { //line variant
            let str =  """
            SET VAR Line stmt (level: \(pInfo.level))
            - setVar: \(self.SetVar)
            - valueExpr: \(self.ValueExpression)
            - modifiers: \(self.ModifiersList.nameString())

            """
            
            return str
        }
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static var register = BlockOrLineTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in
        SetVarStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}

