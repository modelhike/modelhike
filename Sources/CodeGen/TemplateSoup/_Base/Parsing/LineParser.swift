//
// LineParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LineParser {
    private var lines: [String] = []
    private var _curLineNo: Int = 0
    private var _breakParsing: Bool = false
    private var file: LocalFile?
    private let ctx: Context
    
    public var curLineNoForDisplay: Int { _curLineNo + 1 }
    
    public func parse(till endKeyWord: String? = nil, lineHandler: ((_ firstWord: String, _ secondWord: String?, _ line: String, Context) throws -> ())) throws {
        resetFlags()
        
        while linesRemaining {
            if isCurrentLineEmpty() { skipEmptyLine() ; continue }
            if isCurrentLineCommented() { skipCommentedLine(); continue }
            
            //the currentLine() returns a trummed string, while removes prefixed space for content;
            //so, another method, that does not trim prefix, is used for content
            let curLine = currentLine_TrimTrailing()
            let (firstWord, secondWord) = curLine.firstAndsecondWord()
            
            if let firstWord = firstWord,
               let secondWord = secondWord {
                    
                    if let endKeyWord = endKeyWord {
                        if secondWord == endKeyWord {
                            ctx.debugLog.line(curLine, lineNo: curLineNoForDisplay)
                            ctx.debugLog.parseLines(ended: endKeyWord, lineNo: curLineNoForDisplay)
                            
                            //skipLine()
                            break
                        }
                    }
                    
                    ctx.debugLog.line(curLine, lineNo: curLineNoForDisplay)
                    
                    try lineHandler(firstWord, secondWord, curLine, ctx)
            } else {
                try lineHandler("", secondWord, curLine, ctx)
            }
            
            if _breakParsing {break}
            
            incrementLineNo()
        }
            
        resetFlags()
    }
    
    public func skipLine() {
        ctx.debugLog.skipLine(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func skipEmptyLine() {
        ctx.debugLog.skipEmptyLine(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func skipCommentedLine() {
        //here debug flag is used directly, as only is that comment flag is set
        //extra processing to print comments will be carried out
        if ctx.debugLog.flags.onCommentedLines {
            let line = (self.lines[self._curLineNo]).trim()
            ctx.debugLog.comment(line: line, lineNo: curLineNoForDisplay)
        }
        
        _curLineNo += 1;
    }
    
    public func skipLine(by times : Int) {
        ctx.debugLog.skipLine(lineNo: curLineNoForDisplay)

        _curLineNo += times;
    }
    
    public func incrementLineNo() {
        ctx.debugLog.incrementLineNo(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func parseLinesTill(lineHasOnly txt: String) -> [String] {
        var newLines: [String] = []
    
        while linesRemaining {
            if isCurrentLineEmpty() { skipEmptyLine(); continue }
            if isCurrentLineCommented() { skipCommentedLine(); continue }

            let line = currentLine()
            
            if line.hasOnly(txt) {
                break
            }
            
            newLines.append(line)
            incrementLineNo()
        }
        
        return newLines
    }
    
    public func getRemainingLinesAsString() -> String {
        var newLines: [String] = []
    
        while linesRemaining {
            if isCurrentLineEmpty() { skipEmptyLine(); continue }
            if isCurrentLineCommented() { skipCommentedLine(); continue }

            let line = currentLine()
            
            newLines.append(line)
            incrementLineNo()
        }
        
        return newLines.joined(separator: .newLine)
    }
    
    public var linesRemaining: Bool { self._curLineNo < self.lines.count }
    
    public func breakParsing() {
        self._breakParsing = true
    }
    
    public func continueParsing() {
        self._breakParsing = false
    }
    
    func resetFlags() {
        self._breakParsing = false
    }
    
    public func isCurrentLineEmpty() -> Bool {
        let line = (self.lines[self._curLineNo]).trim()
        return line.isEmpty
    }
    
    public func isCurrentLineCommented() -> Bool {
        let line = (self.lines[self._curLineNo]).trim()
        return line.hasPrefix(TemplateConstants.comments)
    }
    
    public func currentLineWithoutStmtKeyword() -> String {
        return String(currentLine().remainingLine(after: TemplateConstants.stmtKeyWord))
    }
    
    public func currentLine(after firstWord: String) -> String {
        return String(currentLine().remainingLine(after: firstWord))
    }
    
    public func currentLine() -> String {
        if _curLineNo < self.lines.count {
            return (self.lines[self._curLineNo]).trim()
        } else {
            return ""
        }
    }
    
    public func currentLine_TrimTrailing() -> String {
        if _curLineNo < self.lines.count {
            return (self.lines[self._curLineNo]).trimTrailing()
        } else {
            return ""
        }
    }
    
    public func nextLine() -> String {
        if _curLineNo < self.lines.count - 1 {
            return (self.lines[self._curLineNo + 1]).trim()
        } else {
            return ""
        }
    }
    
    public init(context: Context) {
        self.ctx = context
        self._curLineNo = 0
    }
    
    public init(string: String, with context: Context) {
        self.ctx = context
        self._curLineNo = 0
        self.lines = string.components(separatedBy: .newlines)
    }
    
    public init(lines: [String], with context: Context) {
        self.ctx = context
        self._curLineNo = 0
        self.lines = lines
    }
    
    public convenience init?(fileName: String, with context: Context) {
        self.init(file: LocalFile(path: fileName), with: context)
    }
    
    public convenience init?(file: LocalFile, with context: Context) {
        do {
            self.init(context: context)

            self.file = file
            self.lines = try file.readTextLines(ignoreEmptyLines: true)
        } catch {
            return nil
        }
    }
}
