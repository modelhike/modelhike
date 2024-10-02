//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class MultiBlockTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    var level: Int = -1
    var lineNo: Int = -1
    
    var children = GenericStmtsContainer()
    var blocks : [PartOfMultiBlockContainer] = []

    var isEmpty: Bool { children.isEmpty }

    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    private func parseStmtLine(lineParser: LineParser, level: Int, with ctx: Context) throws {
        let line = lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line, level: level, with: ctx)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool { return false }
    
    func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt, with ctx: Context) throws -> PartOfMultiBlockContainer? { return nil }

    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    func parseStmtLineAndBlocks(parser: FileTemplateParser, level: Int, with ctx: Context) throws {
        self.level = level
        self.lineNo = parser.lineParser.curLineNoForDisplay
        
        try parseStmtLine(lineParser: parser.lineParser, level: level, with: ctx)
            
        let stmts = GenericStmtsContainer()

        try FileTemplateParser.parseLines(startingFrom: keyword, till: endKeyword, to: stmts, templateParser: parser, level: level + 1, with: ctx)
        
        var container = self.children
        
        for stmt in stmts {
            if let _ = stmt as? TextContent {
                container.append(stmt)
            } else if let unIdentified = stmt as? UnIdentifiedStmt {
                if let block = try checkIfSupportedAndGetBlock(blockLime: unIdentified, with: ctx) {
                    
                    ctx.debugLog.multiBlockDetected(keyWord: block.firstWord, lineNo: unIdentified.lineNo)
                    
                    container = block
                    self.blocks.append(block)
                } else {
                    ctx.debugLog.multiBlockDetectFailed(line: unIdentified.line, lineNo: unIdentified.lineNo)
                    
                    //unidentified stmt
                    let stmt = UnIdentifiedStmt(line: unIdentified.line, lineNo: unIdentified.lineNo, level: level)
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
    
    public init(startKeyword: String, endKeyword: String) {
        self.keyword = startKeyword
        self.endKeyword = endKeyword
    }
}

public struct MultiBlockTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: MultiBlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String) -> T
    public var kind: TemplateStmtKind { .multiBlock }

    public init(keyword: String, initialiser: @escaping (String) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = "end" + keyword
    }
    
    public func getNewObject() -> T {
        return initialiser(self.endKeyword)
    }
}

public class PartOfMultiBlockContainer : GenericStmtsContainer {
    let lineNo: Int
    let line: String
    let firstWord: String
    
    public init(firstWord: String, line: String, lineNo: Int) {
        self.line = line
        self.lineNo = lineNo
        self.firstWord = firstWord
        
        super.init(.partOfMultiBlock, name: firstWord)
    }
}
