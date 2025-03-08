//
// BlockTemplateStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class BlockTemplateStmt : FileTemplateStatement {
    let keyword : String
    let endKeyword : String
    public private(set) var pInfo: ParsedInfo
    public var lineNo: Int { return pInfo.lineNo }

    var children = GenericStmtsContainer()
    var isEmpty: Bool { children.isEmpty }

    public func execute(with ctx: Context) throws -> String? {
        fatalError("This method must be overridden")
    }
    
    private func parseStmtLine(lineParser: LineParser) throws {
        let line = lineParser.currentLineWithoutStmtKeyword()
        let matched = try matchLine(line: line)
        
        if !matched {
            throw TemplateSoup_ParsingError.invalidStmt(pInfo)
        }
    }
    
    func matchLine(line: String) throws -> Bool {
        fatalError("This method must be overridden")
    }
    
    func appendText(_ item: ContentLine) {
        children.append(item)
    }
    
    func parseStmtLineAndChildren(scriptParser: any ScriptParser, pInfo: ParsedInfo) throws {
        self.pInfo = pInfo
        
        try parseStmtLine(lineParser: pInfo.parser)
                
        try scriptParser.parseLines(startingFrom: keyword, till: endKeyword, to: self.children, level: pInfo.level + 1, with: pInfo.ctx)
        
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

public struct BlockTemplateStmtConfig<T>: FileTemplateStmtConfig, TemplateInitialiserWithArg where T: BlockTemplateStmt {
    public let keyword : String
    private let endKeyword : String
    public let initialiser: (String, ParsedInfo) -> T
    public var kind: TemplateStmtKind { .block }

    public init(keyword: String, initialiser: @escaping (String, ParsedInfo) -> T)  {
        self.keyword = keyword
        self.initialiser = initialiser
        self.endKeyword = TemplateConstants.templateEndKeywordWithHyphen + keyword
    }
    
    public func getNewObject(_ pInfo: ParsedInfo) -> T {
        return initialiser(self.endKeyword, pInfo)
    }
}
