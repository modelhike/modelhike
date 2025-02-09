//
// TemplateSoupParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class TemplateSoupParser : SoupyScriptParser {

    override func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any SoupyScriptStmtContainer, level: Int, with ctx: Context) throws {
        
        ctx.debugLog.parseLines(startingFrom: startKeyword, till: endKeyWord, line: lineParser.currentLine(), lineNo: lineParser.curLineNoForDisplay)
        
        if startKeyword != nil { //parsing a block and not the full file
            lineParser.incrementLineNo()
        }
        
        try lineParser.parse(till: endKeyWord, level: level) {pInfo, secondWord, ctx in
            
            guard pInfo.firstWord == TemplateConstants.stmtKeyWord,
                  let stmtWord = secondWord, stmtWord.trim().isNotEmpty else {
                
                try treatAsContent(pInfo, level: level, container: container)
                return
            }
            
            try handleParsedLine(stmtWord: stmtWord, pInfo: pInfo, container: container)
        }
    }
}


