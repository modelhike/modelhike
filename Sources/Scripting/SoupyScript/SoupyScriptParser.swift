//
// SoupyScriptParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class SoupyScriptParser : ScriptParser {
    public var lineParser: any LineParser
    let ctx: LoadContext
    public var context : Context {ctx}
    public var containers = SoupyScriptStmtContainerList()
    public var currentContainer: any SoupyScriptStmtContainer
    
    public func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any SoupyScriptStmtContainer, level: Int, with ctx: Context) throws {
        
        ctx.debugLog.parseLines(startingFrom: startKeyword, till: endKeyWord, line: lineParser.currentLine(), lineNo: lineParser.curLineNoForDisplay)
        
        if startKeyword != nil { //parsing a block and not the full file
            lineParser.incrementLineNo()
        }
        
        try lineParser.parse(till: endKeyWord, level: level) {pInfo, secondWord in
            //Content lines start with ">" Blockquote character
            if pInfo.firstWord.starts(with: ">") {
                try treatAsContent(pInfo, level: level, container: container)
                return
            }
            
            let stmtWord = pInfo.firstWord
            if stmtWord.trim().isEmpty { return }
            
            try handleParsedLine(stmtWord: stmtWord, pInfo: pInfo, container: container)
        }
    }
    
    public func parse(string: String, identifier: String = "") throws -> SoupyScriptStmtContainerList? {
        self.lineParser = LineParserDuringLoad(string: string, identifier: identifier, with: ctx)
        return try parseContainers()
    }
    
    public func parse(file: LocalFile) throws -> SoupyScriptStmtContainerList? {
        guard let lineParser = LineParserDuringLoad(file: file, with: ctx) else {return nil}
        self.lineParser = lineParser
        return try parseContainers(containerName: file.pathString)
    }
    
    public init(lineParser: LineParserDuringLoad, context: LoadContext) {
        self.ctx = context
        self.currentContainer = GenericStmtsContainer()
        self.lineParser = lineParser
    }
}


