//
//  ScriptParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol ScriptParser : Actor, SendableDebugStringConvertible {
    var context : Context {get}
    var containers : SoupyScriptStmtContainerList {get set}
    var lineParser: LineParser {get}
    var currentContainer: any SoupyScriptStmtContainer {get set}
    func parse(file: LocalFile) async throws -> SoupyScriptStmtContainerList?
    func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, to container: any SoupyScriptStmtContainer, level: Int, with ctx: Context) async throws
}

public extension ScriptParser {
    func parse(fileName: String) async throws -> SoupyScriptStmtContainerList? {
        return try await self.parse(file: LocalFile(path: fileName))
    }
    
    func parseAllLines(to container: any SoupyScriptStmtContainer,  level: Int, with ctx: Context) async throws {
        return try await parseLines(startingFrom: nil, till: nil, to: container, level: level, with: ctx)
    }
    
    func handleParsedLine(stmtWord : String, pInfo: ParsedInfo, container: any SoupyScriptStmtContainer) async throws {
        //visual separators; just ignore
        if stmtWord.hasPrefix("---") || stmtWord.hasPrefix("***") {
            return
        }
        
        if stmtWord == TemplateConstants.templateFunction_start {
            if try await parseStartTemplateFunction(stmtWord: stmtWord, pInfo: pInfo) {
                return //continue after macro fn
            }
        }
        
        try await parseStmts(stmtWord, pInfo: pInfo, to: container, with : pInfo.ctx)
    }
    
    func treatAsContent(_ pInfo: ParsedInfo, level: Int, container: any SoupyScriptStmtContainer) async throws {
        let trimmedLine = pInfo.line.trim()
        if await lineParser.isStatementsPrefixedWithKeyword {
            if trimmedLine == TemplateConstants.stmtKeyWord { //add empty line
                let item = EmptyLine()
                await container.append(item)
                return
            }
        } else {
            if trimmedLine.isEmpty { //add empty line
                let item = EmptyLine()
                await container.append(item)
                return
            }
        }
        
        let item = try await ContentLine(pInfo, level: level)
        await container.append(item)
    }
    
    func parseStmts(_ stmtWord: String, pInfo: ParsedInfo, to container: any SoupyScriptStmtContainer, with ctx: Context) async throws {
        
        var isStmtIdentified = false
        
        for config in await ctx.symbols.template.statements {
            if stmtWord == config.keyword {
                isStmtIdentified = true
                
                if config.kind == .block {
                    await ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    var stmt = config.getNewObject(pInfo) as! BlockTemplateStmt
                    try await stmt.parseStmtLineAndChildren(scriptParser: self)
                    await container.append(stmt)
                    break
                    
                } else if config.kind == .line {
                    await ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    var stmt = config.getNewObject(pInfo) as! LineTemplateStmt
                    try await stmt.parseStmtLine()
                    await container.append(stmt)
                    break
                    
                } else if config.kind == .blockOrLine {
                    await ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    var stmt = config.getNewObject(pInfo) as! BlockOrLineTemplateStmt
                    try await stmt.parseAsPerVariant(scriptParser: self)
                    await container.append(stmt)
                    break
                    
                } else if config.kind == .multiBlock {
                    await ctx.debugLog.stmtDetected(keyWord: config.keyword, pInfo: pInfo)
                    
                    var stmt = config.getNewObject(pInfo) as! MultiBlockTemplateStmt
                    try await stmt.parseStmtLineAndBlocks(scriptParser: self)
                    await container.append(stmt)
                    break
                }
            }
        }
        
        if !isStmtIdentified {
            //most likely, this stmt maybe part of a multi block stmt
            //if so, this will be processed and identified by the multiblock stmt
            let stmt = UnIdentifiedStmt(pInfo: pInfo)
            await container.append(stmt)
        }
    }
    
    func parseStartTemplateFunction(stmtWord: String, pInfo: ParsedInfo) async throws -> Bool {
        let templateFnLine = await lineParser.currentLine(after: stmtWord)
        
        if let match = templateFnLine.wholeMatch(of: CommonRegEx.functionDeclaration_unNamedArgs_Capturing) {
            let (_, templateFnName, paramsString) = match.output
            let params = paramsString.getArray_UsingUnNamedArgsPattern()
            
            let fnName = templateFnName.trim()
            let fnContainer  = TemplateFunctionContainer(name: fnName, params: params, pInfo: pInfo)
            await context.templateFunctions.set(fnName,value: fnContainer)
            
            //templateParser.lineParser.skipLine()
            let topLevel = 0
            
            let startingFrom = "\(TemplateConstants.templateFunction_start) \(templateFnName)"
            try await self.parseLines(startingFrom: startingFrom, till: TemplateConstants.templateFunction_end, to: fnContainer.container, level:  topLevel + 1, with: pInfo.ctx)
            
            return true
        } else {
            throw TemplateSoup_ParsingError.invalidTemplateFunctionStmt(templateFnLine, pInfo)
        }
    }
    
    
    func parseContainers(containerName: String = "string") async throws -> SoupyScriptStmtContainerList? {
        
        containers = SoupyScriptStmtContainerList(name: containerName, currentContainer)
        try await self.parseAllLines(to: self.currentContainer, level: 0, with: context)
        
        return containers
    }
    
    var debugDescription: String { get async {
        return await containers.debugDescription
    }}
}
