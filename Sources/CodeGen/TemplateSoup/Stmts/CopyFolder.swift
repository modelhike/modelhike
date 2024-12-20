//
// CopyFolderStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class CopyFolderStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "copy-folder"

    public private(set) var FromFolder: String = ""
    public private(set) var ToFolder: String = ""
    
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
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, fromValue, toValue) = match.output
        
        self.FromFolder = fromValue
        self.ToFolder = toValue ?? ""
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard FromFolder.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromFolder = try? ctx.evaluate(value: FromFolder, pInfo: pInfo) as? String
                                                                    else { return nil }
        
        try ctx.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        if ToFolder.isEmpty {
            let folderName = fromFolder

            ctx.debugLog.copyingFolder(folderName)
            let file = try ctx.fileGenerator.copyFolder(folderName, pInfo: pInfo)
            try ctx.addGenerated(folderPath: file.outputFolder)
        } else {
            guard let toFolder = try? ctx.evaluate(value: ToFolder, pInfo: pInfo) as? String
                                                                        else { return nil }
            
            ctx.debugLog.copyingFolder(fromFolder, to: toFolder)
            let folder = try ctx.fileGenerator.copyFolder(fromFolder, to: toFolder, pInfo: pInfo)
            try ctx.addGenerated(folderPath: folder.outputFolder)
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
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in CopyFolderStmt(pInfo)}
}

