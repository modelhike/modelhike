//
// RenderFolderStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class RenderFolderStmt: LineTemplateStmt, CallStackable, CustomDebugStringConvertible {
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
        guard let context = ctx as? GenerationContext else { return nil }
        
        guard FromFolder.isNotEmpty else { return nil }
        
        if ctx.workingDirectoryString.isEmpty {
            throw TemplateSoup_EvaluationError.workingDirectoryNotSet(pInfo)
        }
        
        guard let fromFolder = try? ctx.evaluate(value: FromFolder, with: pInfo) as? String
        else {
            throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(FromFolder, pInfo)
        }
        
        try context.fileGenerator.setRelativePath(ctx.workingDirectoryString)
        
        var foldername = ""

        if ToFolder.isEmpty {
            foldername = fromFolder

        } else {
            guard let toFolder = try? ctx.evaluate(value: ToFolder, with: pInfo) as? String
                                                                        else { return nil }
            
            foldername = toFolder
        }
        
        ctx.pushCallStack(self)

        //render the foldername if it has an expression within '{{' and '}}'
        foldername = try ContentHandler.eval(expression: foldername, pInfo: pInfo) ?? foldername
        
        ctx.debugLog.renderingFolder(fromFolder, to: foldername)
        let _ = try context.fileGenerator.renderFolder(fromFolder, to: foldername, with: pInfo)
        //folder rendered successfully
        
        ctx.popCallStack()

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
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in RenderFolderStmt(pInfo)}
}

