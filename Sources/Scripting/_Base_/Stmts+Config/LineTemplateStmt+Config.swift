//
//  LineTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol LineTemplateStmt: FileTemplateStatement, SendableDebugStringConvertible {
    var state: LineTemplateStmtState { get }
    
    func execute(with ctx: Context) async throws -> String?
    mutating func matchLine(line: String) async throws -> Bool
}

extension LineTemplateStmt {
    public var lineNo: Int { return pInfo.lineNo }
    public var pInfo: ParsedInfo { state.pInfo }

    mutating func parseStmtLine() async throws {
        let line = await pInfo.parser.currentLineWithoutStmtKeyword()
        let matched = try await matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
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

public actor LineTemplateStmtState {
    let keyword: String
    let pInfo: ParsedInfo
    
    public init(keyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.pInfo = pInfo
    }
}
