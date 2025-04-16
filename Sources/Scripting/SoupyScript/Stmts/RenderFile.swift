//
//  RenderTemplateFileStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct RenderTemplateFileStmt: LineTemplateStmt, CallStackable, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "render-file"

    public private(set) var ToFile: String = ""
    public private(set) var FromTemplate: String = ""
    
    nonisolated(unsafe)
    let stmtRegex = Regex {
        START_KEYWORD
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.validStringValue
        } transform: { String($0) }
        
        Optionally {
            OneOrMore(.whitespace)
            "as"
            OneOrMore(.whitespace)
            Capture {
                CommonRegEx.validStringValue
            } transform: { String($0) }
        }
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fromTemplate, toFile) = match.output
        
        self.ToFile = toFile ?? ""
        self.FromTemplate = fromTemplate
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard let context = ctx as? GenerationContext else { return nil }
        guard FromTemplate.isNotEmpty else { return nil }
        
        if await ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromTemplate = try? await ctx.evaluate(value: FromTemplate, with: pInfo) as? String
        else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(FromTemplate, pInfo)
        }
        
        try await context.fileGenerator.setRelativePath(ctx.workingDirectoryString)

        var filename = ""
        
        if ToFile.isEmpty {
            filename = fromTemplate
        } else {
            guard let toFile = try? await ctx.evaluate(value: ToFile, with: pInfo) as? String
                                                                        else { return nil }
            filename = toFile
        }
        
        //if handler returns false, dont render file
        if try await !context.events.canRender(filename: filename, templatename: self.FromTemplate, with: pInfo) {
            return nil
        }
        
        await ctx.pushCallStack(self)

        //render the filename if it has an expression within '{{' and '}}'
        filename = try ContentHandler.eval(line: filename, pInfo: pInfo) ?? filename

        await ctx.debugLog.generatingFile(filename, with: fromTemplate)
        if let _ = try await context.fileGenerator.generateFile(filename, template: fromTemplate, with: pInfo) {
            //file generated successfully
        } else {
            await ctx.debugLog.fileNotGenerated(filename, with: fromTemplate)
        }
        
        await ctx.popCallStack()
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        RENDER FILE stmt (level: \(pInfo.level))
        - to: \(self.ToFile)
        - template: \(self.FromTemplate)
        
        """
                
        return str
    }
    
    public var callStackItem: CallStackItem { CallStackItem(self, pInfo: pInfo) }

    public init(_ pInfo: ParsedInfo) {
        state =  LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in RenderTemplateFileStmt(pInfo) }
}

