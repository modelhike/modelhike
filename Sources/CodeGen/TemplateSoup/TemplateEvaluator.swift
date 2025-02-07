//
// TemplateEvaluator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TemplateEvaluator: TemplateSoupEvaluator {
    
    public func execute(template: Template, with context: Context) throws -> String? {
        let contents = template.toString()
        let lineparser = LineParser(string: contents, identifier: template.name, with: context)

        return try execute(lineParser: lineparser, with: context)
    }
    
    public func execute(lineParser: LineParser, with ctx: Context) throws -> String? {

        let parser = TemplateSoupParser(lineParser: lineParser, context: ctx)

        do {
            ctx.debugLog.templateParsingStarting()
            try ctx.events.onBeforeParseTemplate?(lineParser.identifier, ctx)
            
            let curLine = lineParser.currentLine()
            
            if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
                let frontMatter = try FrontMatter (lineParser: lineParser, with: ctx)
                try frontMatter.processVariables()
            }
            
            if let containers = try parser.parseContainers() {
                ctx.debugLog.printParsedTree(for: containers)
                
                ctx.debugLog.templateExecutionStarting()
                try ctx.events.onBeforeParseTemplate?(lineParser.identifier, ctx)

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
            } else if let directive = err as? ParserDirective {
                if case let .excludeFile(filename) = directive {
                    ctx.debugLog.excludingFile(filename)
                    return nil //nothing to generate from this excluded file
                }
            } else {
                throw err
            }
        }
        
        return nil
    }
    
}
 
public protocol TemplateSoupEvaluator {
    func execute(template: Template, with ctx: Context) throws -> String?
}
