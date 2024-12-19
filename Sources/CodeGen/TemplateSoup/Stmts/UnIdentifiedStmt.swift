//
// UnIdentifiedStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class UnIdentifiedStmt: TemplateItem, CustomDebugStringConvertible {
    public let line: String
    public let lineNo: Int
    public private(set) var pInfo: ParsedInfo

    public func execute(with ctx: Context) throws -> String? {
        throw TemplateSoup_EvaluationError.unIdentifiedStmt(lineNo, line)
    }
    
    public var debugDescription: String {
        let str =  """
        UN-IDENTIFIED stmt (level: \(pInfo.level))
        - line: \(line.stmtPartOnly())
        
        """
       
        return str
        
    }

    public init(pInfo: ParsedInfo) {
        self.line = pInfo.line
        self.lineNo = pInfo.lineNo
        self.pInfo = pInfo
    }
}
