//
// ConsoleLogStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class ConsoleLogStmt: LineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "console-log"

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
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, expn) = match.output
        
        self.Expression = expn
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard Expression.isNotEmpty else { return nil }
        
        guard let expn = try? ctx.evaluate(value: Expression, lineNo: lineNo)
                                                                    else { return nil }
        //log to stdout
        print("🏷️ \(expn)")
        
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        CONSOLE LOG stmt (level: \(level))
        - expn: \(self.Expression)
        
        """
                
        return str
    }
    
    public init() {
        super.init(keyword: Self.START_KEYWORD)
    }
    
    static var register = LineTemplateStmtConfig(keyword: START_KEYWORD) { ConsoleLogStmt() }
}


