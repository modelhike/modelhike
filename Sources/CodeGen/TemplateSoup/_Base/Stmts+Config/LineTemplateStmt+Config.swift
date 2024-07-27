//
// LineTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LineTemplateStmt: FileTemplateStatement {
    let keyword : String
    var level: Int = -1
    var lineNo: Int = -1
    
    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    func parseStmtLine(lineParser: LineParser, level: Int, with ctx: Context) throws {
        self.level = level
        self.lineNo = lineParser.curLineNoForDisplay
        
        let line = lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line, level: level, with: ctx)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool { return false }
    
    public init(keyword: String) {
        self.keyword = keyword
    }
}

public struct LineTemplateStmtConfig<T>: FileTemplateStmtConfig, InitialiserWithNoArg where T: LineTemplateStmt {
    public let keyword : String
    public let initialiser: () -> T
    public var kind: TemplateStmtKind { .line }
    
    public init(keyword: String, initialiser: @escaping () -> T) {
        self.keyword = keyword
        self.initialiser = initialiser
    }
    
    public func getNewObject() -> T {
        return initialiser()
    }
}
