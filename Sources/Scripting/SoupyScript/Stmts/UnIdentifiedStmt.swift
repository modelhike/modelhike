//
//  UnIdentifiedStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct UnIdentifiedStmt: TemplateItem, CustomDebugStringConvertible {
    public private(set) var pInfo: ParsedInfo

    public func execute(with ctx: Context) throws -> String? {
        throw TemplateSoup_EvaluationError.unIdentifiedStmt(pInfo)
    }
    
    public var debugDescription: String {
        let str =  """
        UN-IDENTIFIED stmt (level: \(pInfo.level))
        - line: \(pInfo.line.stmtPartOnly())
        
        """
       
        return str
        
    }

    public init(pInfo: ParsedInfo) {
        self.pInfo = pInfo
    }
}
