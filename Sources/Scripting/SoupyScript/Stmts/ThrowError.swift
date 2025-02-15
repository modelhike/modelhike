//
// ThrowErrorStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class ThrowErrorStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "throw-error"

    public private(set) var Expression: String = ""
    
    let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, expn) = match.output
        
        self.Expression = expn
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard Expression.isNotEmpty else { return nil }
        
        //see if it is an expression
        if let expn = try ContentHandler.eval(line: Expression, pInfo: pInfo) {
            throw ParserDirective.throwErrorFromCurrentFile(pInfo.identifier, expn, pInfo)
        }
            
        throw ParserDirective.throwErrorFromCurrentFile(pInfo.identifier, "unknown", pInfo)
    }
    
    public var debugDescription: String {
        let str =  """
        THROW ERROR stmt (level: \(pInfo.level))
        - expn: \(self.Expression)
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        super.init(keyword: Self.START_KEYWORD, pInfo: pInfo)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in ThrowErrorStmt(pInfo) }
}


