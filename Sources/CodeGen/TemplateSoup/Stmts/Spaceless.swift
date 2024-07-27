//
// SpacelessStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class SpacelessStmt: BlockTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "spaceless"
    
    let stmtRegex = Regex {
        START_KEYWORD
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }

        let (_) = match.output
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard let body = try children.execute(with: ctx) else { return nil }
        
        return body.spaceless()
    }
    
    public var debugDescription: String {
        var str =  """
        SPACE-LESS stmt (level: \(level))
        - children:
        
        """
        
        str += debugStringForChildren()
        
        return str
    }
    
    public init(parseTill endKeyWord: String) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord)
    }
    
    static var register = BlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord in SpacelessStmt(parseTill: endKeyWord)
    }
}
