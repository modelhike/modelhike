//
// UnIdentifiedStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class UnIdentifiedStmt: FileTemplateItem, CustomDebugStringConvertible {
    public let line: String
    public let lineNo: Int
    public let level: Int
    
    public func execute(with ctx: Context) throws -> String? {
        throw TemplateSoup_EvaluationError.unIdentifiedStmt(lineNo, line)
    }
    
    public var debugDescription: String {
        let str =  """
        UN-IDENTIFIED stmt (level: \(level))
        - line: \(line.stmtPartOnly())
        
        """
       
        return str
        
    }

    public init(line: String, lineNo: Int, level: Int) {
        self.line = line
        self.lineNo = lineNo
        self.level = level
    }
}
