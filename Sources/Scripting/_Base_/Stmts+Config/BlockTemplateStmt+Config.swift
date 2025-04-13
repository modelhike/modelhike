//
//  BlockTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public final class BlockTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    public let pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    let children = GenericStmtsContainer()
    var isEmpty: Bool { get async { await children.isEmpty } }

    public func execute(with ctx: Context) throws -> String? {
        fatalError(#function + ": This method must be overridden")
    }
    
    private func parseStmtLine(lineParser: LineParser) async throws {
        let line = await lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }
    
    func matchLine(line: String) throws -> Bool {
        fatalError(#function + ": This method must be overridden")
    }
    
    func appendText(_ item: ContentLine) async {
        await children.append(item)
    }
    
    func parseStmtLineAndChildren(scriptParser: any ScriptParser) async throws {
        
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
    
    public init(startKeyword: String, endKeyword: String, pInfo: ParsedInfo) {
        self.keyword = startKeyword
        self.endKeyword = endKeyword
        self.pInfo = pInfo
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
