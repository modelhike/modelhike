//
// FileTemplateParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class FileTemplateParser : CustomDebugStringConvertible {
    let context : Context
    var containers = TemplateStmtContainerList()

    var currentContainer: any TemplateStmtContainer
    var lineParser: LineParser
    
    static func parseAllLines(to container: any TemplateStmtContainer, templateParser: FileTemplateParser, level: Int, with ctx: Context) throws {
        
        return try parseLines(startingFrom: nil, till: nil, to: container, templateParser: templateParser, level: level, with: ctx)
    }
    
    static func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any TemplateStmtContainer, templateParser: FileTemplateParser, level: Int, with ctx: Context) throws {
        
        let lineParser = templateParser.lineParser

        ctx.debugLog.parseLines(startingFrom: startKeyword, till: endKeyWord, line: lineParser.currentLine(), lineNo: lineParser.curLineNoForDisplay)
        
        if startKeyword != nil { //parsing a block and not the full file
            lineParser.incrementLineNo()
        }
        
        try lineParser.parse(till: endKeyWord) {firstWord, secondWord, line, ctx in
            
            guard firstWord == TemplateConstants.stmtKeyWord,
                  let secondWord = secondWord, secondWord.trim().isNotEmpty else {
                
                let trimmedLine = line.trim()
                if trimmedLine == TemplateConstants.stmtKeyWord { //add empty line
                    let item = EmptyLine()
                    container.append(item)
                    return
                }
                
                let item = try ContentLine(line, lineNo: lineParser.curLineNoForDisplay, level: level, with: ctx)
                container.append(item)
            
                return
            }
            
            if secondWord == TemplateConstants.macroFunction_start {
                if try parseStartMacroFunction(secondWord: secondWord, templateParser: templateParser, with: ctx) {
                    return //continue after macro fn
                }
            }
            
            try parseStmts(secondWord, line: line, level : level,
                           templateParser : templateParser,
                           to: container, with : ctx)
            
        }
    }
    
    fileprivate static func parseStmts(_ secondWord: String, line: String, level: Int, templateParser: FileTemplateParser, to container: any TemplateStmtContainer, with ctx: Context) throws {
        
        var isStmtIdentified = false
        let lineParser = templateParser.lineParser

        for config in templateParser.context.symbols.template.statements {
            if secondWord == config.keyword {
                isStmtIdentified = true
                
                if config.kind == .block {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, lineNo: lineParser.curLineNoForDisplay)
                    
                    let stmt = config.getNewObject() as! BlockTemplateStmt
                    try stmt.parseStmtLineAndChildren(parser: templateParser, level: level, with: ctx)
                    container.append(stmt)
                    break
                    
                } else if config.kind == .line {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, lineNo: lineParser.curLineNoForDisplay)
                    
                    let stmt = config.getNewObject() as! LineTemplateStmt
                    try stmt.parseStmtLine(lineParser: templateParser.lineParser, level: level, with: ctx)
                    container.append(stmt)
                    break
                    
                } else if config.kind == .blockOrLine {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, lineNo: lineParser.curLineNoForDisplay)
                    
                    let stmt = config.getNewObject() as! BlockOrLineTemplateStmt
                    try stmt.parseAsPerVariant(parser: templateParser, level: level, with: ctx)
                    container.append(stmt)
                    break
                    
                } else if config.kind == .multiBlock {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, lineNo: lineParser.curLineNoForDisplay)
                    
                    let stmt = config.getNewObject() as! MultiBlockTemplateStmt
                    try stmt.parseStmtLineAndBlocks(parser: templateParser, level: level, with: ctx)
                    container.append(stmt)
                    break
                }
            }
        }
        
        if !isStmtIdentified {
            //most likely, this stmt maybe part of a multi block stmt
            //if so, this will be processed and identified by the multiblock stmt
            let stmt = UnIdentifiedStmt(line: line, lineNo: lineParser.curLineNoForDisplay, level: level)
            container.append(stmt)
        }
    }
    
    fileprivate static func parseStartMacroFunction(secondWord: String, templateParser: FileTemplateParser, with ctx: Context) throws -> Bool {
        let macroFnLine = templateParser.lineParser.currentLine(after: secondWord)
        
        if let match = macroFnLine.wholeMatch(of: CommonRegEx.functionDeclaration_unNamedArgs_Capturing) {
            let (_, macroFnName, paramsString) = match.output
            let params = paramsString.getArray_UsingUnNamedArgsPattern()

            let macroFn  = MacroFunctionContainer(name: macroFnName, params: params, lineNo: templateParser.lineParser.curLineNoForDisplay)
            templateParser.context.macroFunctions[macroFnName] = macroFn
            
            //templateParser.lineParser.skipLine()
            let topLevel = 0
            
            let startingFrom = "\(TemplateConstants.macroFunction_start) \(macroFnName)"
            try FileTemplateParser.parseLines(startingFrom: startingFrom, till: TemplateConstants.macroFunction_end, to: macroFn.container, templateParser: templateParser, level:  topLevel + 1, with: ctx)
            
            return true
        } else {
            return false
        }
    }
    
    public func parse(string: String, with ctx: Context) throws -> TemplateStmtContainerList? {
        let lineParser = LineParser(string: string, with: ctx)
        return try populateContainers(containerName: "string", lineParser: lineParser, with: ctx)
    }
    
    public func parse(file: LocalFile, with ctx: Context) throws -> TemplateStmtContainerList? {
        guard let lineParser = LineParser(file: file, with: ctx) else {return nil}
        return try populateContainers(containerName: file.pathString, lineParser: lineParser, with: ctx)
    }
    
    public func parse(fileName: String, with ctx: Context) throws -> TemplateStmtContainerList? {
        return try self.parse(file: LocalFile(path: fileName), with: ctx)
    }
    
    fileprivate func populateContainers(containerName: String, lineParser: LineParser, with ctx: Context) throws -> TemplateStmtContainerList? {
        
        self.lineParser = lineParser
        
        containers = TemplateStmtContainerList(name: containerName, currentContainer)
        try FileTemplateParser.parseAllLines(to: self.currentContainer, templateParser: self, level: 0, with: ctx)
        
        return containers
    }
    
    public var debugDescription: String {
        return containers.debugDescription
    }
        
    public init(context: Context) {
        self.context = context
        self.currentContainer = GenericStmtsContainer()
        lineParser = LineParser(context: context)
    }
}


