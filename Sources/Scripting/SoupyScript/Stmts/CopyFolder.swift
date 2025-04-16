//
//  CopyFolderStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct CopyFolderStmt: LineTemplateStmt, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "copy-folder"

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
        
        if ToFolder.isEmpty {
            let folderName = fromFolder

            await ctx.debugLog.copyingFolder(folderName)
            let _ = try await context.fileGenerator.copyFolder(folderName, with: pInfo)
            //folder copied successfully
        } else {
            guard let toFolder = try? await ctx.evaluate(value: ToFolder, with: pInfo) as? String
                                                                        else { return nil }
            
            await ctx.debugLog.copyingFolder(fromFolder, to: toFolder)
            let _ = try await context.fileGenerator.copyFolder(fromFolder, to: toFolder, with: pInfo)
            //folder copied successfully
        }
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        COPY FOLDER stmt (level: \(pInfo.level))
        - from: \(self.FromFolder)
        - to: \(self.ToFolder)
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in CopyFolderStmt(pInfo)}
}

