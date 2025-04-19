//
//  LineParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public typealias LineParserDuringLoad = GenericLineParser<LoadContext>
public typealias LineParserDuringGeneration = GenericLineParser<GenerationContext>
public typealias DummyLineParserDuringLoad = GenericLineParser<LoadContext>
public typealias DummyLineParserDuringGeneration = GenericLineParser<GenerationContext>

public protocol LineParser : AnyObject, Actor {
    var ctx: Context {get}
    var identifier: String {get}
    var isStatementsPrefixedWithKeyword: Bool {get}
    
    var curLineNoForDisplay: Int {get}
    var curLevelForDisplay: Int {get}
    var linesRemaining: Bool {get}
    
    func parseLinesTill(lineHasOnly txt: String) async -> [String]
    func parse(till endKeyWord: String?, level: Int, lineHandler: ((_ pctx: ParsedInfo, _ stmtWord: String?) async throws -> ())) async throws
    
    func nextLine() -> String
    func currentLine() -> String
    func currentLine(after firstWord: String) -> String
    func incrementLineNo() async
    func currentLineWithoutStmtKeyword() -> String
    func lookAheadLine(by lineCount: Int) -> String
    
    func isCurrentLineEmpty() -> Bool
    func isCurrentLineCommented() -> Bool
    
    func currentParsedInfo(level: Int) async -> ParsedInfo?
    
    func currentLine_TrimTrailing() -> String
    func skipLine() async
    func skipLine(by times : Int) async
}

public actor GenericLineParser<T> : LineParser where T: Context {
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
    
    public let isStatementsPrefixedWithKeyword: Bool
    
    public func parse(till endKeyWord: String? = nil, level: Int, lineHandler: ((_ pctx: ParsedInfo, _ stmtWord: String?) async throws -> ())) async throws {
        resetFlags()
        
        while linesRemaining {
            if isCurrentLineEmpty() { await skipEmptyLine() ; continue }
            if isCurrentLineCommented() { await skipCommentedLine(); continue }
            
            //the currentLine() returns a trimmed string, which removes prefixed space for content;
            //so, another method, that does not trim prefix, is used for content
            guard var pInfo = await self.currentParsedInfo(level: level) else { await self.skipLine(); continue }

            let curLine = pInfo.line
            
            var stmtWord = ""
                    
            if isStatementsPrefixedWithKeyword {
                guard let secondWord = pInfo.secondWord else {
                    pInfo.firstWord("")
                    try await lineHandler(pInfo, nil)
                    
                    if await !miscLineReadHandling() {break}
                    continue
                }
                
                stmtWord = secondWord
            } else {
                stmtWord = pInfo.firstWord
            }
            
            if let endKeyWord = endKeyWord {
                //E.g. consider a block as ending, when either of the foll are encountered:
                //"end-<block keyword>" or "end"
                if stmtWord == endKeyWord || stmtWord == TemplateConstants.templateEndKeyword {
                    await ctx.debugLog.line(curLine, pInfo: pInfo)
                    await ctx.debugLog.parseLines(ended: endKeyWord, pInfo: pInfo)
                    
                    //skipLine()
                    break
                }
            }
            
            await ctx.debugLog.line(curLine, pInfo: pInfo)
            
            try await lineHandler(pInfo, stmtWord)
            
            
            if await !miscLineReadHandling() {break}
        }
            
        resetFlags()
    }
    
    private func miscLineReadHandling() async -> Bool {
        if _breakParsing {return false}
        
        if autoIncrementLineNoForEveryLoop {
            await incrementLineNo()
        }
        
        return true
    }
    
    public func skipLine() async {
        await ctx.debugLog.skipLine(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func skipEmptyLine() async {
        await ctx.debugLog.skipEmptyLine(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func skipCommentedLine() async {
        //here debug flag is used directly, as only is that comment flag is set
        //extra processing to print comments will be carried out
        if await ctx.debugLog.flags.onCommentedLines {
            let line = (self.lines[self._curLineNo]).trim()
            await ctx.debugLog.comment(line: line, lineNo: curLineNoForDisplay)
        }
        
        _curLineNo += 1;
    }
    
    public func skipLine(by times : Int) async {
        await ctx.debugLog.skipLine(lineNo: curLineNoForDisplay)

        _curLineNo += times;
    }
    
    public func incrementLineNo() async {
        await ctx.debugLog.incrementLineNo(lineNo: curLineNoForDisplay)
        
        _curLineNo += 1;
    }
    
    public func parseLinesTill(lineHasOnly txt: String) async -> [String] {
        var newLines: [String] = []
    
        while linesRemaining {
            if isCurrentLineEmpty() { await skipEmptyLine(); continue }
            if isCurrentLineCommented() { await skipCommentedLine(); continue }

            let line = currentLine()
            
            if line.hasOnly(txt) {
                break
            }
            
            newLines.append(line)
            await incrementLineNo()
        }
        
        return newLines
    }
    
    public func getRemainingLinesAsString() async -> String {
        var newLines: [String] = []
    
        while linesRemaining {
            if isCurrentLineEmpty() { await skipEmptyLine(); continue }
            if isCurrentLineCommented() { await skipCommentedLine(); continue }

            let line = currentLine()
            
            newLines.append(line)
            await incrementLineNo()
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
        
    public func currentParsedInfo(level: Int) async -> ParsedInfo? {
        self._curLevel = level
        guard let pInfo = await ParsedInfo(parser: self) else { return nil }
        
        if await ctx.debugLog.flags.lineByLineParsing {
            await ctx.debugLog.line(currentLine(), pInfo: pInfo)
        }
        
        return pInfo
    }
        
    public func currentLineWithoutStmtKeyword() -> String {
        if isStatementsPrefixedWithKeyword {
            return String(currentLine().remainingLine(after: TemplateConstants.stmtKeyWord))
        } else {
            return String(currentLine())
        }
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
    
    internal init(identifier: String, isStatementsPrefixedWithKeyword: Bool, with context: T) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.autoIncrementLineNoForEveryLoop = true
        
        self.isStatementsPrefixedWithKeyword = isStatementsPrefixedWithKeyword
    }
    
    public init(string: String, identifier: String, isStatementsPrefixedWithKeyword: Bool, with context: T) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.lines = string.splitIntoLines()
        self.autoIncrementLineNoForEveryLoop = true
        
        self.isStatementsPrefixedWithKeyword = isStatementsPrefixedWithKeyword
    }
    
    public init(lines: [String], identifier: String, isStatementsPrefixedWithKeyword: Bool, with context: T, autoIncrementLineNoForEveryLoop : Bool = true) {
        self.context = context
        self.identifier = identifier
        
        self._curLineNo = 0
        self.lines = lines
        self.autoIncrementLineNoForEveryLoop = autoIncrementLineNoForEveryLoop
        
        self.isStatementsPrefixedWithKeyword = isStatementsPrefixedWithKeyword
    }
    
    public init?(file: LocalFile, isStatementsPrefixedWithKeyword: Bool, with context: T) {
        do {
            self.context = context
            self.identifier = file.name
            
            self._curLineNo = 0
            self.autoIncrementLineNoForEveryLoop = true
            
            self.isStatementsPrefixedWithKeyword = isStatementsPrefixedWithKeyword
            
            self.file = file
            self.lines = try file.readTextLines(ignoreEmptyLines: true)
        } catch {
            return nil
        }
    }
    
    public init?(fileName: String, isStatementsPrefixedWithKeyword: Bool, with context: T) {
        self.init(file: LocalFile(path: fileName), isStatementsPrefixedWithKeyword: isStatementsPrefixedWithKeyword, with: context)
    }
}

public extension LineParser {
    
    func isCurrentLineEmptyOrCommented() -> Bool {
        return isCurrentLineEmpty() || isCurrentLineCommented()
    }

    func isCurrentLineHumaneComment(_ pctx: ParsedInfo) async -> Bool {
        if pctx.firstWord.isStartingWithAlphabet {
            let nextLine = await pctx.parser.nextLine().trim()
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
