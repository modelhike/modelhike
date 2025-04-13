//
//  BlockTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol BlockOrLineTemplateStmt: FileTemplateStatement {
    var state: BlockOrLineTemplateStmtState { get }
    
    func execute(with ctx: Context) async throws -> String?
    func checkIfLineVariant(line: String) -> Bool
    mutating func matchLine_BlockVariant(line: String) throws -> Bool
    mutating func matchLine_LineVariant(line: String) throws -> Bool
}

extension BlockOrLineTemplateStmt {
    public var children: GenericStmtsContainer { state.children }
    public var pInfo: ParsedInfo { state.pInfo }
    public var keyword: String { state.keyword }
    public var endKeyword: String { state.endKeyword }
    public var isEmpty: Bool  { get async { await children.isEmpty } }
    public var lineNo: Int { return pInfo.lineNo }

    private mutating func parseStmtLine_BlockVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_BlockVariant(line: line)

        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }

    private mutating func parseStmtLine_LineVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_LineVariant(line: line)

        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }


    func appendText(_ item: ContentLine) async {
        await children.append(item)
    }

    private mutating func parseStmtLineAndChildren(line: String, scriptParser: any ScriptParser) async throws {

        try parseStmtLine_BlockVariant(line: line, lineParser: pInfo.parser)

        try await scriptParser.parseLines(
            startingFrom: keyword, till: endKeyword, to: self.children, level: pInfo.level + 1,
            with: pInfo.ctx)
    }

    mutating func parseAsPerVariant(scriptParser: any ScriptParser) async throws {
        let line = await pInfo.parser.currentLineWithoutStmtKeyword()

        if checkIfLineVariant(line: line) {
            await state.isBlockVariant(false)
            try parseStmtLine_LineVariant(line: line, lineParser: pInfo.parser)
        } else {
            await state.isBlockVariant(true)
            try await parseStmtLineAndChildren(line: line, scriptParser: scriptParser)
        }
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

public struct BlockOrLineTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg
where T: BlockOrLineTemplateStmt {
    public let keyword: String
    private let endKeyword: String
    public let initialiser: @Sendable (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .blockOrLine }

    public init(keyword: String, initialiser: @Sendable @escaping (String, ParsedInfo) -> T) {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = TemplateConstants.templateEndKeywordWithHyphen + keyword
    }

    public init(
        keyword: String, endKeyword: String, initialiser: @Sendable @escaping (String, ParsedInfo) -> T
    ) {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = endKeyword
    }

    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}

public actor BlockOrLineTemplateStmtState {
    let keyword: String
    let endKeyword: String
    let pInfo: ParsedInfo
    let children = GenericStmtsContainer()
    
    var isBlockVariant: Bool = false
    func isBlockVariant(_ value: Bool ){
        isBlockVariant = value
    }
    
    public init(keyword: String, endKeyword: String, pInfo: ParsedInfo) {
        self.keyword = keyword
        self.endKeyword = endKeyword
        self.pInfo = pInfo
    }
}
