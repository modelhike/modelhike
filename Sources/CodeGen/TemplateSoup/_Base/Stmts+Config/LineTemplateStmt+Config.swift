//
// LineTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LineTemplateStmt: FileTemplateStatement {
    let keyword : String
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }
    
    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    func parseStmtLine() throws {
        let line = pInfo.parser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    func matchLine(line: String) throws -> Bool { return false }
    
    public init(keyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.pInfo = pInfo
    }
}

public struct LineTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithNoArg where T: LineTemplateStmt {
    public let keyword : String
    public let initialiser: (ParsedInfo) -> T
    public var kind: TemplateStmtKind { .line }
    
    public init(keyword: String, initialiser: @escaping (ParsedInfo) -> T) {
        self.keyword = keyword
        self.initialiser = initialiser
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(pInfo)
    }
}
