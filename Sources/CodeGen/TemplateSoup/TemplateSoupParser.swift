//
//  TemplateSoupParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor TemplateSoupParser: ScriptParser {
    public var lineParser: any LineParser
    let ctx: GenerationContext
    public var context: Context { ctx }

    public var containers = SoupyScriptStmtContainerList()
    public var currentContainer: any SoupyScriptStmtContainer

    public func parseLines(
        startingFrom startKeyword: String?, till endKeyWord: String?,
        to container: any SoupyScriptStmtContainer, level: Int, with ctx: Context
    ) async throws {

        await ctx.debugLog.parseLines(
            startingFrom: startKeyword, till: endKeyWord, line: lineParser.currentLine(),
            lineNo: lineParser.curLineNoForDisplay)

        if startKeyword != nil {  //parsing a block and not the full file
            await lineParser.incrementLineNo()
        }

        try await lineParser.parse(till: endKeyWord, level: level) {[weak self] pInfo, stmtWord in
            guard let self = self else { return }

            guard pInfo.firstWord == TemplateConstants.stmtKeyWord,
                let stmtWord = stmtWord, stmtWord.trim().isNotEmpty
            else {

                try await treatAsContent(pInfo, level: level, container: container)
                return
            }

            try await handleParsedLine(stmtWord: stmtWord, pInfo: pInfo, container: container)
        }
    }

    public func parse(string: String, identifier: String = "") async throws
        -> SoupyScriptStmtContainerList?
    {
        self.lineParser = LineParserDuringGeneration(
            string: string, identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx
        )
        return try await parseContainers()
    }

    public func parse(file: LocalFile) async throws -> SoupyScriptStmtContainerList? {
        guard
            let lineParser = LineParserDuringGeneration(
                file: file, isStatementsPrefixedWithKeyword: true, with: ctx)
        else { return nil }
        self.lineParser = lineParser
        return try await parseContainers(containerName: file.pathString)
    }

    public init(lineParser: LineParserDuringGeneration, context: GenerationContext) {
        self.ctx = context
        self.currentContainer = GenericStmtsContainer()
        self.lineParser = lineParser
    }
}
