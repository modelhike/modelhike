//
//  SpacelessStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class SpacelessStmt: BlockTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "spaceless"
    
    let stmtRegex = Regex {
        START_KEYWORD
        
        CommonRegEx.comments
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: stmtRegex ) else { return false }

        let (_) = match.output
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard let body = try children.execute(with: ctx) else { return nil }
        
        //removes all spaces in the string
        //for selective spaces, replace 🔥 symbol with a single space
        return body.spaceless()
    }
    
    public var debugDescription: String {
        var str =  """
        SPACE-LESS stmt (level: \(pInfo.level))
        - children:
        
        """
        
        str += debugStringForChildren()
        
        return str
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static var register = BlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in SpacelessStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}
