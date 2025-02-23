//
// LineParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias LineParserDuringLoad = GenericLineParser<LoadContext>
public typealias LineParserDuringGeneration = GenericLineParser<GenerationContext>
public typealias DummyLineParserDuringLoad = GenericLineParser<LoadContext>
public typealias DummyLineParserDuringGeneration = GenericLineParser<GenerationContext>

public protocol LineParser : AnyObject {
    var ctx: Context {get}
    var identifier: String {get}
    var curLineNoForDisplay: Int {get}
    var curLevelForDisplay: Int {get}
    var linesRemaining: Bool {get}
    
    func parseLinesTill(lineHasOnly txt: String) -> [String]
    func parse(till endKeyWord: String?, level: Int, lineHandler: ((_ pctx: ParsedInfo, _ secondWord: String?) throws -> ())) throws
    
    func nextLine() -> String
    func currentLine() -> String
    func currentLine(after firstWord: String) -> String
    func incrementLineNo()
    func currentLineWithoutStmtKeyword() -> String
    func lookAheadLine(by lineCount: Int) -> String
    
    func isCurrentLineEmpty() -> Bool
    func isCurrentLineCommented() -> Bool
    
    func currentParsedInfo(level: Int) -> ParsedInfo?
    
    func currentLine_TrimTrailing() -> String
    func skipLine()
    func skipLine(by times : Int)
}

public class GenericLineParser<T> : LineParser where T: Context {
    private var lines: [String] = []
    private var _curLineNo: Int = 0
    private var _curLevel: Int = 0
    private var _breakParsing: Bool = false
    private var file: LocalFile?
    internal let context: T
    public var ctx: Context { context }
    
    private let autoIncrementLineNoForEveryLoop: Bool
    public private(set) var identifier: String
    
    public var curLineNoForDisplay: Int { _curLineNo + 1 }
    public var curLevelForDisplay: Int { _curLevel }
    
    public func parse(till endKeyWord: String? = nil, level: Int, lineHandler: ((_ pctx: ParsedInfo, _ secondWord: String?) throws -> ())) throws {
        resetFlags()
        
        while linesRemaining {
            if isCurrentLineEmpty() { skipEmptyLine() ; continue }
            if isCurrentLineCommented() { skipCommentedLine(); continue }
            
            //the currentLine() returns a trummed string, which removes prefixed space for content;
            //so, another method, that does not trim prefix, is used for content
            guard let pInfo = self.currentParsedInfo(level: level) else { self.skipLine(); continue }

            let curLine = pInfo.line
            let (firstWord, secondWord) = curLine.firstAndsecondWord()
            
            if let _ = firstWord,
               let secondWord = secondWord {
                    
                    if let endKeyWord = endKeyWord {
                        if secondWord == endKeyWord {
                            ctx.debugLog.line(curLine, pInfo: pInfo)
                            ctx.debugLog.parseLines(ended: endKeyWord, pInfo: pInfo)
                            
                            //skipLine()
                            break
                        }
                    }
                    
                    ctx.debugLog.line(curLine, pInfo: pInfo)
                    
                try lineHandler(pInfo, secondWord)
            } else {
                pInfo.firstWord = ""
                try lineHandler(pInfo, secondWord)
            }
            
            if _breakParsing {break}
            
            if autoIncrementLineNoForEveryLoop {
                incrementLineNo()
            }
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
        
    public func currentParsedInfo(level: Int) -> ParsedInfo? {
        self._curLevel = level
        guard let pInfo = ParsedInfo(parser: self) else { return nil }
        
        if ctx.debugLog.flags.lineByLineParsing {
            ctx.debugLog.line(currentLine(), pInfo: pInfo)
        }
        
        return pInfo
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
    
    public func lookAheadLine(by lineCount: Int) -> String {
        if _curLineNo < self.lines.count - lineCount {
            return (self.lines[self._curLineNo + lineCount]).trim()
        } else {
            return ""
        }
    }
    
    internal init(identifier: String, with context: T) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.autoIncrementLineNoForEveryLoop = true
    }
    
    public init(string: String, identifier: String, with context: T) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.lines = string.splitIntoLines()
        self.autoIncrementLineNoForEveryLoop = true
    }
    
    public init(lines: [String], identifier: String, with context: T, autoIncrementLineNoForEveryLoop : Bool = true) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.lines = lines
        self.autoIncrementLineNoForEveryLoop = autoIncrementLineNoForEveryLoop
    }
    
    public convenience init?(file: LocalFile, with context: T) {
        do {
            self.init(identifier: file.name, with: context)
            
            self.file = file
            self.lines = try file.readTextLines(ignoreEmptyLines: true)
        } catch {
            return nil
        }
    }
    
    public convenience init?(fileName: String, with context: T) {
        self.init(file: LocalFile(path: fileName), with: context)
    }
}

public extension LineParser {
    
    func isCurrentLineEmptyOrCommented() -> Bool {
        return isCurrentLineEmpty() || isCurrentLineCommented()
    }

    func isCurrentLineHumaneComment(_ pctx: ParsedInfo) -> Bool {
        if pctx.firstWord.isStartingWithAlphabet {
            let nextLine = pctx.parser.nextLine().trim()
            if nextLine.isEmpty {
                return true
            }
            
            if let firstWord = nextLine.firstWord(), firstWord.isStartingWithAlphabet {
                return true
            }
        }
        
        return false

    }
}
