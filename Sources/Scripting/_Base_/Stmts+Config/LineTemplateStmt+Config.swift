//
//  LineTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public final class LineTemplateStmt: FileTemplateStatement {
    let keyword : String
    public let pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }
    
    public func execute(with ctx: Context) throws -> String? {
        fatalError(#function + ": This method must be overridden")
    }
    
    func parseStmtLine() async throws {
        let line = await pInfo.parser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }
    
    func matchLine(line: String) throws -> Bool {
        fatalError(#function + ": This method must be overridden")
    }
    
    public init(keyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.pInfo = pInfo
    }
}

public struct LineTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithNoArg where T: LineTemplateStmt {
    public let keyword : String
    public let initialiser: @Sendable (ParsedInfo) -> T
    public var kind: TemplateStmtKind { .line }
    
    public init(keyword: String, initialiser: @escaping @Sendable (ParsedInfo) -> T) {
        self.keyword = keyword
        self.initialiser = initialiser
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(pInfo)
    }
}
