//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class BlockOrLineTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    var level: Int = -1
    var lineNo: Int = -1
    
    var children = GenericStmtsContainer()
    var isEmpty: Bool { children.isEmpty }
    var isBlockVariant: Bool = false
    
    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    private func parseStmtLine_BlockVariant(line: String, lineParser: LineParser, level: Int, with ctx: Context) throws {
        let matched = try matchLine_BlockVariant(line: line, level: level, with: ctx)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    private func parseStmtLine_LineVariant(line: String, lineParser: LineParser, level: Int, with ctx: Context) throws {
        let matched = try matchLine_LineVariant(line: line, level: level, with: ctx)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    func checkIfLineVariant(line: String, level: Int) -> Bool { return false }
    
    func matchLine_BlockVariant(line: String, level: Int, with ctx: Context) throws -> Bool { return false }
    func matchLine_LineVariant(line: String, level: Int, with ctx: Context) throws -> Bool { return false }

    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    private func parseStmtLineAndChildren(line : String, parser: TemplateSoupParser, level: Int, with ctx: Context) throws {
        self.level = level
        self.lineNo = parser.lineParser.curLineNoForDisplay
        
        try parseStmtLine_BlockVariant(line : line, lineParser: parser.lineParser, level: level, with: ctx)
                
        try TemplateSoupParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, templateParser: parser, level: level + 1, with: ctx)
    }

    func parseAsPerVariant(parser: TemplateSoupParser, level: Int, with ctx: Context) throws {
        let line = parser.lineParser.currentLineWithoutStmtKeyword()

        if checkIfLineVariant(line: line, level: level) {
            isBlockVariant = false
            try parseStmtLine_LineVariant(line : line, lineParser: parser.lineParser, level: level, with: ctx)
        } else {
            isBlockVariant = true
            try parseStmtLineAndChildren(line : line, parser: parser, level: level, with: ctx)
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

public struct BlockOrLineTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: BlockOrLineTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String) -> T
    public var kind: TemplateStmtKind { .blockOrLine }

    public init(keyword: String, initialiser: @escaping (String) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = "end" + keyword
    }
    
    public init(keyword: String, endKeyword: String, initialiser: @escaping (String) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = endKeyword
    }
    
    public func getNewObject() -> T {
        return initialiser(self.endKeyword)
    }
}
