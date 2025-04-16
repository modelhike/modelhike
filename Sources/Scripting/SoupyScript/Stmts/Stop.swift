//
//  StopRenderingCurrentTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct StopRenderingCurrentTemplateStmt: LineTemplateStmt, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "stop-render"

    public private(set) var Expression: String = ""
    
    nonisolated(unsafe)
    let stmtRegex = Regex {
        START_KEYWORD
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_) = match.output
                
        return true
    }
    
    public func execute(with ctx: Context) throws -> String? {
        throw ParserDirective.stopRenderingCurrentFile(pInfo.identifier, pInfo)
    }
    
    public var debugDescription: String {
        let str =  """
        STOP RENDER stmt (level: \(pInfo.level))
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        state=LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in StopRenderingCurrentTemplateStmt(pInfo) }
}


