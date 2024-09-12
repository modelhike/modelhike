//
// CopyFileStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
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
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fromValue, toValue) = match.output
        
        self.FromFile = fromValue
        self.ToFile = toValue ?? ""
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard FromFile.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw EvaluationError.workingDirectoryNotSet(lineNo)
        }
        
        guard let fromFile = try? ctx.evaluate(value: FromFile, lineNo: lineNo) as? String
                                                                    else { return nil }
        
        try ctx.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        if ToFile.isEmpty {
            let fileName = fromFile

            ctx.debugLog.copyingFile(fileName)
            let file = try ctx.fileGenerator.copyFile(fileName)
            ctx.addGenerated(filePath: file.outputPath.string + fileName)
        } else {
            guard let toFile = try? ctx.evaluate(value: ToFile, lineNo: lineNo) as? String
                                                                        else { return nil }
            
            ctx.debugLog.copyingFile(fromFile, to: toFile)
            let file = try ctx.fileGenerator.copyFile(fromFile, to: toFile)
            ctx.addGenerated(filePath: file.outputPath.string + toFile)
        }
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        COPY FILE stmt (level: \(level))
        - from: \(self.FromFile)
        - to: \(self.ToFile)
        
        """
                
        return str
    }
    
    public init() {
        super.init(keyword: Self.START_KEYWORD)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) { CopyFileStmt()}
}

