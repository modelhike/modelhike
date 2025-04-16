//
//  RenderFolderStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct RenderFolderStmt: LineTemplateStmt, CallStackable, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "render-folder"

    public private(set) var FromFolder: String = ""
    public private(set) var ToFolder: String = ""
    
    nonisolated(unsafe)
    let stmtRegex = Regex {
        START_KEYWORD
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.validStringValue
        } transform: { String($0) }
        
        Optionally {
            OneOrMore(.whitespace)
            "to"
            OneOrMore(.whitespace)
            Capture {
                CommonRegEx.validStringValue
            } transform: { String($0) }
        }
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fromValue, toValue) = match.output
        
        self.FromFolder = fromValue
        self.ToFolder = toValue ?? ""
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard let context = ctx as? GenerationContext else { return nil }
        
        guard FromFolder.isNotEmpty else { return nil }
        
        if await ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromFolder = try? await ctx.evaluate(value: FromFolder, with: pInfo) as? String
        else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(FromFolder, pInfo)
        }
        
        try await context.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        var foldername = ""

        if ToFolder.isEmpty {
            foldername = fromFolder

        } else {
            guard let toFolder = try? await ctx.evaluate(value: ToFolder, with: pInfo) as? String
                                                                        else { return nil }
            
            foldername = toFolder
        }
        
        await ctx.pushCallStack(self)

        //render the foldername if it has an expression within '{{' and '}}'
        foldername = try ContentHandler.eval(expression: foldername, pInfo: pInfo) ?? foldername
        
        await ctx.debugLog.renderingFolder(fromFolder, to: foldername)
        let _ = try await context.fileGenerator.renderFolder(fromFolder, to: foldername, with: pInfo)
        //folder rendered successfully
        
        await ctx.popCallStack()

        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        RENDER FOLDER stmt (level: \(pInfo.level))
        - from: \(self.FromFolder)
        - to: \(self.ToFolder)
        
        """
                
        return str
    }
    
    public var callStackItem: CallStackItem { CallStackItem(self, pInfo: pInfo) }

    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in RenderFolderStmt(pInfo)}
}

