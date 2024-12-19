//
// RenderFolderStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class RenderFolderStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "render-folder"

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
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(lineNo)
        }
        
        guard let fromFolder = try? ctx.evaluate(value: FromFolder, pInfo: pInfo) as? String
                                                                    else { return nil }
        
        try ctx.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        var foldername = ""

        if ToFolder.isEmpty {
            foldername = fromFolder

        } else {
            guard let toFolder = try? ctx.evaluate(value: ToFolder, pInfo: pInfo) as? String
                                                                        else { return nil }
            
            foldername = toFolder
        }
        
        //render the foldername if it has an expression within '{{' and '}}'
        foldername = try ContentHandler.eval(expression: foldername, with: ctx) ?? foldername
        
        ctx.debugLog.renderingFolder(fromFolder, to: foldername)
        let folder = try ctx.fileGenerator.renderFolder(fromFolder, to: foldername)
        try ctx.addGenerated(folderPath: folder.outputFolder)
        
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
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in RenderFolderStmt(pInfo)}
}

