//
//  ConsoleLogStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct ConsoleLogStmt: LineTemplateStmt, CustomDebugStringConvertible {
    public var state: LineTemplateStmtState
    
    static let START_KEYWORD = "console-log"

    public private(set) var Expression: String = ""
    
    nonisolated(unsafe)
    let stmtRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }
        
        let (_, expn) = match.output
        
        self.Expression = expn
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard Expression.isNotEmpty else { return nil }
        
        //see if it is an object
        if let expn = try? await ctx.evaluate(value: Expression, with: pInfo) {
            if expn is String {
                print("🏷️ [Line \(lineNo)] \(expn)")
            } else if let obj = deepUnwrap(expn) {
                //log to stdout
                
                if let debugInfo = obj as? CustomDebugStringConvertible {
                    print("🏷️ [Line \(lineNo)] \(debugInfo.debugDescription)")
                } else {
                    print("🏷️ [Line \(lineNo)] \(obj)")
                }
            }
            return nil
        }
        
        //see if it is an expression
        if let expn = try? await ctx.evaluate(expression: Expression, with: pInfo) {
            print("🏷️ [Line \(lineNo)] \(expn)")
            return nil
        }
            
        print("🏷️🎈[Line no: \(lineNo)] - nothing to show")
        return nil
    }
    
    public var debugDescription: String {
        let str =  """
        CONSOLE LOG stmt (level: \(pInfo.level))
        - expn: \(self.Expression)
        
        """
                
        return str
    }
    
    public init(_ pInfo: ParsedInfo) {
        state = LineTemplateStmtState(keyword: Self.START_KEYWORD, pInfo: pInfo)

    }
    
    static let register = LineTemplateStmtConfig(keyword: START_KEYWORD) {pInfo in ConsoleLogStmt(pInfo) }
}


