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
        fatalError("This method must be overridden")
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
        fatalError("This method must be overridden")
    }
    
    func matchLine_BlockVariant(line: String) throws -> Bool {
        fatalError("This method must be overridden")
    }
    
    func matchLine_LineVariant(line: String) throws -> Bool {
        fatalError("This method must be overridden")
    }

    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    private func parseStmtLineAndChildren(line : String, scriptParser: any ScriptParser) throws {
        
        try parseStmtLine_BlockVariant(line : line, lineParser: pInfo.parser)
                
        try scriptParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, level: pInfo.level + 1, with: pInfo.ctx)
    }

    func parseAsPerVariant(scriptParser: any ScriptParser) throws {
        let line = pInfo.parser.currentLineWithoutStmtKeyword()

        if checkIfLineVariant(line: line) {
            isBlockVariant = false
            try parseStmtLine_LineVariant(line : line, lineParser: pInfo.parser)
        } else {
            isBlockVariant = true
            try parseStmtLineAndChildren(line : line, scriptParser: scriptParser)
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
