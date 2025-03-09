//
//  RenderTemplateFileStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class RenderTemplateFileStmt: LineTemplateStmt, CallStackable, CustomDebugStringConvertible {
    static let START_KEYWORD = "render-file"

    public private(set) var ToFile: String = ""
    public private(set) var FromTemplate: String = ""
    
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
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fromTemplate, toFile) = match.output
        
        self.ToFile = toFile ?? ""
        self.FromTemplate = fromTemplate
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard let context = ctx as? GenerationContext else { return nil }
        guard FromTemplate.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromTemplate = try? ctx.evaluate(value: FromTemplate, with: pInfo) as? String
        else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(FromTemplate, pInfo)
        }
        
        try context.fileGenerator.setRelativePath(ctx.workingDirectoryString)

        var filename = ""
        
        if ToFile.isEmpty {
            filename = fromTemplate
        } else {
            guard let toFile = try? ctx.evaluate(value: ToFile, with: pInfo) as? String
                                                                        else { return nil }
            filename = toFile
        }
        
        ctx.pushCallStack(self)

        //render the filename if it has an expression within '{{' and '}}'
        filename = try ContentHandler.eval(line: filename, pInfo: pInfo) ?? filename

        ctx.debugLog.generatingFile(filename, with: fromTemplate)
        if let _ = try context.fileGenerator.generateFile(filename, template: fromTemplate, with: pInfo) {
            //file generated successfully
        } else {
            ctx.debugLog.fileNotGenerated(filename, with: fromTemplate)
        }
        
        ctx.popCallStack()
        
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
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in RenderTemplateFileStmt(pInfo) }
}

