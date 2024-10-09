//
// TemplateSoupParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class TemplateSoupParser : CustomDebugStringConvertible {
    let context : Context
    var containers = TemplateStmtContainerList()

    var currentContainer: any TemplateStmtContainer
    var lineParser: LineParser
    
    static func parseAllLines(to container: any TemplateStmtContainer, templateParser: TemplateSoupParser, level: Int, with ctx: Context) throws {
        
        return try parseLines(startingFrom: nil, till: nil, to: container, templateParser: templateParser, level: level, with: ctx)
    }
    
    static func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any TemplateStmtContainer, templateParser: TemplateSoupParser, level: Int, with ctx: Context) throws {
        
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
            
            //visual separators; just ignore
            if secondWord.hasPrefix("---") || secondWord.hasPrefix("***") {
                return
            }
            
            if secondWord == TemplateConstants.templateFunction_start {
                if try parseStartTemplateFunction(secondWord: secondWord, templateParser: templateParser, with: ctx) {
                    return //continue after macro fn
                }
            }
            
            try parseStmts(secondWord, line: line, level : level,
                           templateParser : templateParser,
                           to: container, with : ctx)
            
        }
    }
    
    fileprivate static func parseStmts(_ secondWord: String, line: String, level: Int, templateParser: TemplateSoupParser, to container: any TemplateStmtContainer, with ctx: Context) throws {
        
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
    
    fileprivate static func parseStartTemplateFunction(secondWord: String, templateParser: TemplateSoupParser, with ctx: Context) throws -> Bool {
        let templateFnLine = templateParser.lineParser.currentLine(after: secondWord)
        
        if let match = templateFnLine.wholeMatch(of: CommonRegEx.functionDeclaration_unNamedArgs_Capturing) {
            let (_, templateFnName, paramsString) = match.output
            let params = paramsString.getArray_UsingUnNamedArgsPattern()

            let fnName = templateFnName.trim()
            let fnContainer  = TemplateFunctionContainer(name: fnName, params: params, lineNo: templateParser.lineParser.curLineNoForDisplay)
            templateParser.context.templateFunctions[fnName] = fnContainer
            
            //templateParser.lineParser.skipLine()
            let topLevel = 0
            
            let startingFrom = "\(TemplateConstants.templateFunction_start) \(templateFnName)"
            try TemplateSoupParser.parseLines(startingFrom: startingFrom, till: TemplateConstants.templateFunction_end, to: fnContainer.container, templateParser: templateParser, level:  topLevel + 1, with: ctx)
            
            return true
        } else {
            throw TemplateSoup_ParsingError.invalidTemplateFunctionStmt(templateFnLine)
        }
    }
    
    public func parse(string: String, identifier: String = "") throws -> TemplateStmtContainerList? {
        self.lineParser = LineParser(string: string, identifier: identifier, with: context)
        return try populateContainers()
    }
    
    public func parse(file: LocalFile) throws -> TemplateStmtContainerList? {
        guard let lineParser = LineParser(file: file, with: context) else {return nil}
        self.lineParser = lineParser
        return try populateContainers(containerName: file.pathString)
    }
    
    public func parse(fileName: String) throws -> TemplateStmtContainerList? {
        return try self.parse(file: LocalFile(path: fileName))
    }
    
    public func populateContainers(containerName: String = "string") throws -> TemplateStmtContainerList? {
                
        containers = TemplateStmtContainerList(name: containerName, currentContainer)
        try TemplateSoupParser.parseAllLines(to: self.currentContainer, templateParser: self, level: 0, with: context)
        
        return containers
    }
    
    public var debugDescription: String {
        return containers.debugDescription
    }
    
    public init(lineParser: LineParser, context: Context) {
        self.context = context
        self.currentContainer = GenericStmtsContainer()
        self.lineParser = lineParser
    }
}


