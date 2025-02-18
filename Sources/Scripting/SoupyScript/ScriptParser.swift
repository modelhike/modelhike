//
// ScriptParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public protocol ScriptParser : AnyObject, CustomDebugStringConvertible {
    var context : Context {get}
    var containers : SoupyScriptStmtContainerList {get set}
    var lineParser: LineParser {get}
    var currentContainer: any SoupyScriptStmtContainer {get set}
    func parse(file: LocalFile) throws -> SoupyScriptStmtContainerList?
    func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any SoupyScriptStmtContainer, level: Int, with ctx: Context) throws
}

public extension ScriptParser {
    func parse(fileName: String) throws -> SoupyScriptStmtContainerList? {
        return try self.parse(file: LocalFile(path: fileName))
    }
    
    func parseAllLines(to container: any SoupyScriptStmtContainer,  level: Int, with ctx: Context) throws {
        return try parseLines(startingFrom: nil, till: nil, to: container, level: level, with: ctx)
    }
    
    func handleParsedLine(stmtWord : String, pInfo: ParsedInfo, container: any SoupyScriptStmtContainer) throws {
        //visual separators; just ignore
        if stmtWord.hasPrefix("---") || stmtWord.hasPrefix("***") {
            return
        }
        
        if stmtWord == TemplateConstants.templateFunction_start {
            if try parseStartTemplateFunction(secondWord: stmtWord, pInfo: pInfo) {
                return //continue after macro fn
            }
        }
        
        try parseStmts(stmtWord, pInfo: pInfo, to: container, with : pInfo.ctx)
    }
    
    func treatAsContent(_ pInfo: ParsedInfo, level: Int, container: any SoupyScriptStmtContainer) throws {
        let trimmedLine = pInfo.line.trim()
        if trimmedLine == TemplateConstants.stmtKeyWord { //add empty line
            let item = EmptyLine()
            container.append(item)
            return
        }
        
        let item = try ContentLine(pInfo, level: level)
        container.append(item)
    }
    
    func parseStmts(_ secondWord: String, pInfo: ParsedInfo, to container: any SoupyScriptStmtContainer, with ctx: Context) throws {
        
        var isStmtIdentified = false

        for config in ctx.symbols.template.statements {
            if secondWord == config.keyword {
                isStmtIdentified = true
                
                if config.kind == .block {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    let stmt = config.getNewObject(pInfo) as! BlockTemplateStmt
                    try stmt.parseStmtLineAndChildren(scriptParser: self, pInfo: pInfo)
                    container.append(stmt)
                    break
                    
                } else if config.kind == .line {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    let stmt = config.getNewObject(pInfo) as! LineTemplateStmt
                    try stmt.parseStmtLine()
                    container.append(stmt)
                    break
                    
                } else if config.kind == .blockOrLine {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    let stmt = config.getNewObject(pInfo) as! BlockOrLineTemplateStmt
                    try stmt.parseAsPerVariant(scriptParser: self)
                    container.append(stmt)
                    break
                    
                } else if config.kind == .multiBlock {
                    ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    let stmt = config.getNewObject(pInfo) as! MultiBlockTemplateStmt
                    try stmt.parseStmtLineAndBlocks(scriptParser: self)
                    container.append(stmt)
                    break
                }
            }
        }
        
        if !isStmtIdentified {
            //most likely, this stmt maybe part of a multi block stmt
            //if so, this will be processed and identified by the multiblock stmt
            let stmt = UnIdentifiedStmt(pInfo: pInfo)
            container.append(stmt)
        }
    }
    
    func parseStartTemplateFunction(secondWord: String, pInfo: ParsedInfo) throws -> Bool {
        let templateFnLine = lineParser.currentLine(after: secondWord)
        
        if let match = templateFnLine.wholeMatch(of: CommonRegEx.functionDeclaration_unNamedArgs_Capturing) {
            let (_, templateFnName, paramsString) = match.output
            let params = paramsString.getArray_UsingUnNamedArgsPattern()

            let fnName = templateFnName.trim()
            let fnContainer  = TemplateFunctionContainer(name: fnName, params: params, pInfo: pInfo)
            context.templateFunctions[fnName] = fnContainer
            
            //templateParser.lineParser.skipLine()
            let topLevel = 0
            
            let startingFrom = "\(TemplateConstants.templateFunction_start) \(templateFnName)"
            try self.parseLines(startingFrom: startingFrom, till: TemplateConstants.templateFunction_end, to: fnContainer.container, level:  topLevel + 1, with: pInfo.ctx)
            
            return true
        } else {
            throw TemplateSoup_ParsingError.invalidTemplateFunctionStmt(templateFnLine, pInfo)
        }
    }
    
    func parseContainers(containerName: String = "string") throws -> SoupyScriptStmtContainerList? {
                
        containers = SoupyScriptStmtContainerList(name: containerName, currentContainer)
        try self.parseAllLines(to: self.currentContainer, level: 0, with: context)
        
        return containers
    }
    
    public var debugDescription: String {
        return containers.debugDescription
    }
}
