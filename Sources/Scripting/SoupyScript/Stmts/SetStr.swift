//
//  SetStrVarStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct SetStrVarStmt: BlockOrLineTemplateStmt, CustomDebugStringConvertible {
    
    public var state: BlockOrLineTemplateStmtState
    
    static let START_KEYWORD = "set-str"

    public private(set) var SetVar: String = ""
    public private(set) var ValueExpression: String = ""
    public private(set) var ModifiersList: [ModifierInstance] = []

    nonisolated(unsafe)
    let setVarBlockRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variableOrObjectProperty
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
        
        CommonRegEx.comments
    }
    
    nonisolated(unsafe)
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
    
    public func checkIfLineVariant(line: String) -> Bool {
        let match = line.wholeMatch(of: setVarLineRegex )
        return match != nil
    }

    public mutating func matchLine_BlockVariant(line: String) async throws -> Bool {
        guard let match = line.wholeMatch(of: setVarBlockRegex )
                                                                else { return false }

        let (_, setVar, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = ""
        self.ModifiersList = try await Modifiers.parse(string: modifiersList, pInfo: pInfo)

        return true
    }
    
    public mutating func matchLine_LineVariant(line: String) async throws -> Bool {
        guard let match = line.wholeMatch(of: setVarLineRegex )
                                                                else { return false }
        
        let (_, setVar, value, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = value
        self.ModifiersList = try await Modifiers.parse(string: modifiersList, pInfo: pInfo)

        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        var actualBody: Any? = nil
        
        if isBlockVariant {
            guard SetVar.isNotEmpty,
                  await children.count != 0 else { return nil }
            
            if let body = try await children.execute(with: ctx) {
                let modifiedBody = try await Modifiers.apply(to: body.trim(), modifiers: self.ModifiersList, with: pInfo)
                actualBody = modifiedBody
            } else { //for block variant, return empty string for invalid cases
                actualBody = String.empty
            }
        } else {
            guard SetVar.isNotEmpty,
                  ValueExpression.isNotEmpty else { return nil }
            
            if let body = try ContentHandler.eval(line: ValueExpression, pInfo: pInfo) {
                let modifiedBody = try await Modifiers.apply(to: body, modifiers: self.ModifiersList, with: pInfo)
                actualBody = modifiedBody
            } else {
                actualBody = nil
            }
        }
            
        let variableName = self.SetVar

        if actualBody != nil {
            //special handling for setting current working directory
            if await ctx.isWorkingDirectoryVariable(variableName) {
                if let str = actualBody as? String {
                    await ctx.debugLog.workingDirectoryChanged(str)
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
        get async {
            if self.isBlockVariant {
                var str =  """
            SET STR VAR Block stmt (level: \(pInfo.level))
            - setVar: \(self.SetVar)
            - modifiers: \(self.ModifiersList.nameString())
            - children:
            
            """
                
                str += debugStringForChildren()
                
                return str
                
            } else { //line variant
                let str =  """
            SET STR VAR Line stmt (level: \(pInfo.level))
            - setVar: \(self.SetVar)
            - valueExpr: \(self.ValueExpression)
            - modifiers: \(self.ModifiersList.nameString())
            
            """
                
                return str
            }
        }
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        state = BlockOrLineTemplateStmtState(keyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static let register = BlockOrLineTemplateStmtConfig(keyword: START_KEYWORD, endKeyword: "end-set") { endKeyWord, pInfo in
        SetStrVarStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}

