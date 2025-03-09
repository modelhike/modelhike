//
//  CopyFileStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class CopyFileStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "copy-file"

    public private(set) var FromFile: String = ""
    public private(set) var ToFile: String = ""
    
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
        
        let (_, fromValue, toValue) = match.output
        
        self.FromFile = fromValue
        self.ToFile = toValue ?? ""
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard let context = ctx as? GenerationContext else { return nil }
        guard FromFile.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromFile = try? ctx.evaluate(value: FromFile, with: pInfo) as? String
        else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(FromFile, pInfo)
        }
        
        try context.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        if ToFile.isEmpty {
            let fileName = fromFile

            ctx.debugLog.copyingFile(fileName)
            let _ = try context.fileGenerator.copyFile(fileName, with: pInfo)
            //file generated successfully
        } else {
            guard let toFile = try? ctx.evaluate(value: ToFile, with: pInfo) as? String
                                                                        else { return nil }
            
            ctx.debugLog.copyingFile(fromFile, to: toFile)
            let _ = try context.fileGenerator.copyFile(fromFile, to: toFile, with: pInfo)
            //file generated successfully
        }
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        COPY FILE stmt (level: \(pInfo.level))
        - from: \(self.FromFile)
        - to: \(self.ToFile)
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in CopyFileStmt(pInfo)}
}

