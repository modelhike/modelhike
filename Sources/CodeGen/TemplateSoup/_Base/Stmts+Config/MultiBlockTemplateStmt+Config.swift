//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class MultiBlockTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    var children = GenericStmtsContainer()
    var blocks : [PartOfMultiBlockContainer] = []

    var isEmpty: Bool { children.isEmpty }

    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    private func parseStmtLine(lineParser: LineParser) throws {
        let line = lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }
    
    func matchLine(line: String) throws -> Bool { return false }
    
    func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt) throws -> PartOfMultiBlockContainer? { return nil }

    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    func parseStmtLineAndBlocks(parser: TemplateSoupParser) throws {
        try parseStmtLine(lineParser: parser.lineParser)
            
        let stmts = GenericStmtsContainer()
        let ctx = parser.context
        
        try TemplateSoupParser.parseLines(startingFrom: keyword, till: endKeyword, to: stmts, templateParser: parser, level: pInfo.level + 1, with: ctx)
        
        var container = self.children
        
        for stmt in stmts {
            if let _ = stmt as? TextContent {
                container.append(stmt)
            } else if let unIdentified = stmt as? UnIdentifiedStmt {
                if let block = try checkIfSupportedAndGetBlock(blockLime: unIdentified) {
                    
                    ctx.debugLog.multiBlockDetected(keyWord: block.firstWord, pInfo: unIdentified.pInfo)
                    
                    container = block
                    self.blocks.append(block)
                } else {
                    ctx.debugLog.multiBlockDetectFailed(pInfo: unIdentified.pInfo)
                    
                    //unidentified stmt
                    let stmt = UnIdentifiedStmt(pInfo: unIdentified.pInfo)
                    container.append(stmt)
                }
            } else { //identified stmt
                container.append(stmt)
            }
        }
        
    }
    
    internal func debugStringForChildren() -> String {
        var str = ""
        
        for item in children {
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

public struct MultiBlockTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: MultiBlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .multiBlock }

    public init(keyword: String, initialiser: @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = "end" + keyword
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}

public class PartOfMultiBlockContainer : GenericStmtsContainer {
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }
    let firstWord: String
    
    public init(firstWord: String, pInfo: ParsedInfo) {
        self.firstWord = firstWord
        self.pInfo = pInfo
        
        super.init(.partOfMultiBlock, name: firstWord)
    }
}
