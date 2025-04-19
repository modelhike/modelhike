//
//  SetVarStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct SetVarStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "set"

    public private(set) var SetVar: String = ""
    public private(set) var ValueExpression: String = ""
    public private(set) var ModifiersList: [ModifierInstance] = []

    public let state: LineTemplateStmtState
    
    nonisolated(unsafe)
    let setVarLineRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variableOrObjectProperty
        } transform: {
            String($0)
        }
        OneOrMore(.whitespace)

        "="

        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: {
            String($0)
        }

        CommonRegEx.modifiersForExpression_Capturing

        CommonRegEx.comments
    }

    public mutating func matchLine(line: String) async throws -> Bool {
        guard let match = line.wholeMatch(of: setVarLineRegex)
        else { return false }

        let (_, setVar, value, modifiersList) = match.output
        self.SetVar = setVar
        self.ValueExpression = value
        self.ModifiersList = try await Modifiers.parse(string: modifiersList, pInfo: pInfo)

        return true
    }

    public func execute(with ctx: Context) async throws -> String? {
        var actualBody: Sendable? = nil

        guard SetVar.isNotEmpty,
            ValueExpression.isNotEmpty
        else { return nil }

        if let body = try await ctx.evaluate(expression: ValueExpression, with: pInfo) {
            let modifiedBody = try await Modifiers.apply(
                to: body, modifiers: self.ModifiersList, with: pInfo)
            actualBody = modifiedBody
        }

        let variableName = self.SetVar

        if actualBody != nil {
            //special handling for setting current working directory
            if await ctx.isWorkingDirectoryVariable(variableName) {
                if let str = actualBody as? String {
                    await ctx.debugLog.workingDirectoryChanged(str)
                    await ctx.variables.set(variableName, value: str)
                }
            } else {
                try await ctx.setValueOf(variableOrObjProp: variableName, value: actualBody, with: pInfo)
            }
        } else {

            //special handling for setting current working directory
            if await ctx.isWorkingDirectoryVariable(variableName) {
                //reset to base path
                await ctx.debugLog.workingDirectoryChanged("(base path)")
                await ctx.variables.set(variableName, value: "")
            } else {
                try await ctx.setValueOf(variableOrObjProp: variableName, value: nil, with: pInfo)
            }
        }

        return nil
    }

    public var debugDescription: String {
        let str = """
            SET VAR Line stmt (level: \(pInfo.level))
            - setVar: \(self.SetVar)
            - valueExpr: \(self.ValueExpression)
            - modifiers: \(self.ModifiersList.nameString())

            """

        return str
    }

    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }

    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) { pInfo in
        SetVarStmt(pInfo)
    }
}
