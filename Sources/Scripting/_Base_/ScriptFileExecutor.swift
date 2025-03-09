//
// ScriptFileExecutor.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ScriptFileExecutor: SoupyScriptExecutor {
    
    public func execute(script scriptFile: Script, with context: GenerationContext) throws -> String? {
        let contents = scriptFile.toString()
        let lineparser = LineParserDuringGeneration(string: contents, identifier: scriptFile.name, isStatementsPrefixedWithKeyword: false, with: context)

        return try execute(lineParser: lineparser, with: context)
    }
    
    public func execute(lineParser: LineParserDuringGeneration, with ctx: GenerationContext) throws -> String? {

        let parser = SoupyScriptParser(lineParser: lineParser, context: ctx)

        do {
            ctx.debugLog.scriptFileParsingStarting()
            try ctx.events.onBeforeParseScriptFile?(lineParser.identifier, ctx)
            
            let curLine = lineParser.currentLine()
            
            if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
                let frontMatter = try FrontMatter (lineParser: lineParser, with: ctx)
                try frontMatter.processVariables()
            }
            
            if let containers = try parser.parseContainers() {
                ctx.debugLog.printParsedTree(for: containers)
                
                ctx.debugLog.scriptFileExecutionStarting()
                try ctx.events.onBeforeExecuteScriptFile?(lineParser.identifier, ctx)

                if let body = try containers.execute(with: ctx) {
                    return body
                }
            }
        } catch let err {
            if let parseErr = err as? TemplateSoup_ParsingError {
                throw ParsingError.invalidLine(parseErr.pInfo, parseErr)
            } else if let evalErr = err as? TemplateSoup_EvaluationError {
                if case let .workingDirectoryNotSet(pInfo) = evalErr {
                    throw EvaluationError.workingDirectoryNotSet(pInfo, evalErr)
                } else if case let .unIdentifiedStmt(pInfo) = evalErr {
                    throw EvaluationError.invalidLine(pInfo, evalErr)
                } else {
                    throw EvaluationError.invalidLine(evalErr.pInfo, evalErr)
                }
//            } else if let directive = err as? ParserDirective {
//                if case let .excludeFile(filename) = directive {
//                    ctx.debugLog.excludingFile(filename)
//                    return nil //nothing to generate from this excluded file
//                } else if case let .stopRenderingCurrentFile(filename, pInfo) = directive {
//                    ctx.debugLog.stopRenderingCurrentFile(filename, pInfo: pInfo)
//                    return nil //nothing to generate from this rendering stopped file
//                } else if case let .throwErrorFromCurrentFile(filename, errMsg, pInfo) = directive {
//                    ctx.debugLog.throwErrorFromCurrentFile(filename, err: errMsg, pInfo: pInfo)
//                    throw EvaluationError.templateRenderingError(pInfo, directive)
//                }
            } else {
                throw err
            }
        }
        
        return nil
    }
    
}
 
public protocol SoupyScriptExecutor {
    func execute(script: Script, with ctx: GenerationContext) throws -> String?
}
