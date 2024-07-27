//
// RenderFileWithTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class RenderFileWithTemplateStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "render-file"

    public private(set) var ToFile: String = ""
    public private(set) var FromTemplate: String = ""
    
    let stmtRegex = Regex {
        START_KEYWORD
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.validStringValue
        } transform: { String($0) }
        OneOrMore(.whitespace)
        
        "with-template"
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.validStringValue
        } transform: { String($0) }
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, toFile, fromTemplate) = match.output
        
        self.ToFile = toFile
        self.FromTemplate = fromTemplate
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard ToFile.isNotEmpty,
              FromTemplate.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw EvaluationError.workingDirectoryNotSet(lineNo)
        }
        
        guard let toFile = try? ctx.evaluate(value: ToFile, lineNo: lineNo) as? String ,
              let fromTemplate = try? ctx.evaluate(value: FromTemplate, lineNo: lineNo) as? String
                                                                        else { return nil }
        let fileName = toFile
        try ctx.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        ctx.debugLog.generatingFile(fileName, with: fromTemplate)
        let file = try ctx.fileGenerator.generateFile(fileName, template: fromTemplate)
        
        ctx.addGenerated(filePath: file.outputPath.string + fileName)
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        RENDER FILE stmt (level: \(level))
        - to: \(self.ToFile)
        - template: \(self.FromTemplate)
        
        """
                
        return str
    }
    
    public init() {
        super.init(keyword: Self.START_KEYWORD)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) { RenderFileWithTemplateStmt() }
}

