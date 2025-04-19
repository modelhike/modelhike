//
//  BlockTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol BlockTemplateStmt : SendableDebugStringConvertible, FileTemplateStatement {
    var state: BlockTemplateStmtState { get }
    
    func execute(with ctx: Context) async throws -> String?
    mutating func matchLine(line: String) throws -> Bool
}

extension BlockTemplateStmt {
    public var children: GenericStmtsContainer { state.children }
    public var pInfo: ParsedInfo { state.pInfo }
    public var keyword: String { state.keyword }
    public var endKeyword: String { state.endKeyword }
    public var isEmpty: Bool  { get async { await children.isEmpty } }
    public var lineNo: Int { return pInfo.lineNo }
    
    private mutating func parseStmtLine(lineParser: LineParser) async throws {
        let line = await lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }
    
    func appendText(_ item: ContentLine) async {
        await children.append(item)
    }
    
    mutating func parseStmtLineAndChildren(scriptParser: any ScriptParser) async throws {
        
        try await parseStmtLine(lineParser: pInfo.parser)
                
        try await scriptParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, level: pInfo.level + 1, with: pInfo.ctx)
        
    }
    
    internal func debugStringForChildren() async -> String {
        var str = ""
        
        for item in await children.snapshot() {
            if let debug = item as? CustomDebugStringConvertible {
                str += " -- " + debug.debugDescription + "\n"
            }
        }
        
        return str
    }
}

public struct BlockTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: BlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser:@Sendable (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .block }

    public init(keyword: String, initialiser: @Sendable @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = TemplateConstants.templateEndKeywordWithHyphen + keyword
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}

public actor BlockTemplateStmtState {
    let keyword: String
    let endKeyword: String
    public let pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    let children = GenericStmtsContainer()
    var isEmpty: Bool  { get async { await children.isEmpty } }
    
    public init(keyword: String, endKeyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.endKeyword = endKeyword
        self.pInfo = pInfo
    }
}
