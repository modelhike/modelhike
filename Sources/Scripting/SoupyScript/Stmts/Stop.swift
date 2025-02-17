//
// StopRenderingCurrentTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class StopRenderingCurrentTemplateStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "stop-render"

    public private(set) var Expression: String = ""
    
    let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_) = match.output
                
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        throw ParserDirective.stopRenderingCurrentFile(pInfo.identifier, pInfo)
    }
    
    public var debugDescription: String {
        let str =  """
        STOP RENDER stmt (level: \(pInfo.level))
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in StopRenderingCurrentTemplateStmt(pInfo) }
}


