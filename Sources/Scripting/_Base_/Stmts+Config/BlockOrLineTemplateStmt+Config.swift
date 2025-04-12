//
//  BlockTemplateStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public final class BlockOrLineTemplateStmt: FileTemplateStatement {
    let keyword: String
    let endKeyword: String
    public let pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    let children = GenericStmtsContainer()
    var isEmpty: Bool  { get async { await children.isEmpty } }
    var isBlockVariant: Bool { get async { await state.isBlockVariant }}
    let state = BlockOrLineTemplateState()
    public func execute(with ctx: Context) throws -> String? {
        fatalError(#function + ": This method must be overridden")
    }

    private func parseStmtLine_BlockVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_BlockVariant(line: line)

        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }

    private func parseStmtLine_LineVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_LineVariant(line: line)

        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }

    func checkIfLineVariant(line: String) -> Bool {
        fatalError(#function + ": This method must be overridden")
    }

    func matchLine_BlockVariant(line: String) throws -> Bool {
        fatalError(#function + ": This method must be overridden")
    }

    func matchLine_LineVariant(line: String) throws -> Bool {
        fatalError(#function + ": This method must be overridden")
    }

    func appendText(_ item: ContentLine) async {
        await children.append(item)
    }

    private func parseStmtLineAndChildren(line: String, scriptParser: any ScriptParser) async throws {

        try parseStmtLine_BlockVariant(line: line, lineParser: pInfo.parser)

        try await scriptParser.parseLines(
            startingFrom: keyword, till: endKeyword, to: self.children, level: pInfo.level + 1,
            with: pInfo.ctx)
    }

    func parseAsPerVariant(scriptParser: any ScriptParser) async throws {
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

    public init(startKeyword: String, endKeyword: String, pInfo: ParsedInfo) {
        self.keyword = startKeyword
        self.endKeyword = endKeyword
        self.pInfo = pInfo
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

actor BlockOrLineTemplateState {
    var isBlockVariant: Bool = false
    func isBlockVariant(_ value: Bool ){
        isBlockVariant = value
    }
}
