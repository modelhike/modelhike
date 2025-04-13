//
//  BlockTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol MultiBlockTemplateStmt : FileTemplateStatement {
    var state: MutipleBlockTemplateStmtState { get }
    
    func execute(with ctx: Context) async throws -> String?
    mutating func matchLine(line: String) throws -> Bool
}

extension MultiBlockTemplateStmt {
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
    
    func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt) throws -> PartOfMultiBlockContainer? { return nil }

    func appendText(_ item: ContentLine) async {
        await state.children.append(item)
    }
    
    mutating func parseStmtLineAndBlocks(scriptParser: any ScriptParser) async throws {
        try await parseStmtLine(lineParser: pInfo.parser)
            
        let stmts = GenericStmtsContainer()
        let ctx = pInfo.ctx
        
        try await scriptParser.parseLines(startingFrom: keyword, till: endKeyword, to: stmts, level: pInfo.level + 1, with: ctx)
        
        var container = state.children
        
        for stmt in await stmts.snapshot() {
            if let _ = stmt as? TextContent {
               await container.append(stmt)
            } else if let unIdentified = stmt as? UnIdentifiedStmt {
                if let block = try checkIfSupportedAndGetBlock(blockLime: unIdentified) {
                    
                    await ctx.debugLog.multiBlockDetected(keyWord: block.firstWord, pInfo: unIdentified.pInfo)
                    
                    container = block.container
                    await state.addBlock(block)
                } else {
                    await ctx.debugLog.multiBlockDetectFailed(pInfo: unIdentified.pInfo)
                    
                    //unidentified stmt
                    throw TemplateSoup_EvaluationError.unIdentifiedStmt(unIdentified.pInfo)
                }
            } else { //identified stmt
                await container.append(stmt)
            }
        }
        
    }
    
    internal func debugStringForChildren() async -> String {
        var str = ""
        
        for item in await state.children.snapshot() {
            if let debug = item as? CustomDebugStringConvertible {
                str += " -- " + debug.debugDescription + "\n"
            }
        }
        
        return str
    }
}

public struct MultiBlockTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: MultiBlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: @Sendable (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .multiBlock }

    public init(keyword: String, initialiser: @Sendable @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = TemplateConstants.templateEndKeywordWithHyphen + keyword
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}

public actor PartOfMultiBlockContainer {
    let container: GenericStmtsContainer
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }
    let firstWord: String
    
    public init(firstWord: String, pInfo: ParsedInfo) {
        self.firstWord = firstWord
        self.pInfo = pInfo
        
        container = .init(.partOfMultiBlock, name: firstWord)
    }
}

public actor MutipleBlockTemplateStmtState {
    let keyword: String
    let endKeyword: String
    let pInfo: ParsedInfo
    
    let children = GenericStmtsContainer()
    var blocks : [PartOfMultiBlockContainer] = []
    
//    func children(_ value: GenericStmtsContainer){
//        children = value
//    }
    
    func addBlock(_ block: PartOfMultiBlockContainer){
        blocks.append(block)
    }
    
    public init(keyword: String, endKeyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.endKeyword = endKeyword
        self.pInfo = pInfo
    }
}
