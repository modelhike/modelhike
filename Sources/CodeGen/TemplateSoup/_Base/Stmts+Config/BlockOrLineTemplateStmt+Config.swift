//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class BlockOrLineTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    var children = GenericStmtsContainer()
    var isEmpty: Bool { children.isEmpty }
    var isBlockVariant: Bool = false
    
    public func execute(with ctx: Context) throws -> String? {
        return nil
    }
    
    private func parseStmtLine_BlockVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_BlockVariant(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    private func parseStmtLine_LineVariant(line: String, lineParser: LineParser) throws {
        let matched = try matchLine_LineVariant(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(line)
        }
    }
    
    func checkIfLineVariant(line: String) -> Bool { return false }
    
    func matchLine_BlockVariant(line: String) throws -> Bool { return false }
    func matchLine_LineVariant(line: String) throws -> Bool { return false }

    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    private func parseStmtLineAndChildren(line : String, parser: TemplateSoupParser) throws {
        
        try parseStmtLine_BlockVariant(line : line, lineParser: parser.lineParser)
                
        try TemplateSoupParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, templateParser: parser, level: pInfo.level + 1, with: parser.context)
    }

    func parseAsPerVariant(parser: TemplateSoupParser) throws {
        let line = parser.lineParser.currentLineWithoutStmtKeyword()

        if checkIfLineVariant(line: line) {
            isBlockVariant = false
            try parseStmtLine_LineVariant(line : line, lineParser: parser.lineParser)
        } else {
            isBlockVariant = true
            try parseStmtLineAndChildren(line : line, parser: parser)
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

public struct BlockOrLineTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: BlockOrLineTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .blockOrLine }

    public init(keyword: String, initialiser: @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = "end" + keyword
    }
    
    public init(keyword: String, endKeyword: String, initialiser: @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = endKeyword
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}
