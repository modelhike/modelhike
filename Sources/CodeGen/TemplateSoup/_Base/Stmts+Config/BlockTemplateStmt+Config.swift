//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class BlockTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    var level: Int = -1
    var lineNo: Int = -1
    
    var children = GenericStmtsContainer()
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
    
    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    func parseStmtLineAndChildren(parser: FileTemplateParser, level: Int, with ctx: Context) throws {
        self.level = level
        self.lineNo = parser.lineParser.curLineNoForDisplay
        
        try parseStmtLine(lineParser: parser.lineParser, level: level, with: ctx)
                
        try FileTemplateParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, templateParser: parser, level: level + 1, with: ctx)
        
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

public struct BlockTemplateStmtConfig<T>: FileTemplateStmtConfig, InitialiserWithArg where T: BlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String) -> T
    public var kind: TemplateStmtKind { .block }

    public init(keyword: String, initialiser: @escaping (String) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = "end" + keyword
    }
    
    public func getNewObject() -> T {
        return initialiser(self.endKeyword)
    }
}
