//
// TemplateEvaluator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TemplateEvaluator: TemplateSoupEvaluator {
    
    public func execute(template: Template, context: Context) throws -> String? {
        let contents = template.toString()
        let lineparser = LineParser(string: contents, with: context)

        return try execute(identifier: template.name, lineparser: lineparser, with: context)
    }
    
    public func execute(identifier: String, lineparser: LineParser, with ctx: Context) throws -> String? {

        let parser = FileTemplateParser(lineparser: lineparser, context: ctx)

        do {
            
            ctx.debugLog.templateParsingStarting()
            
            if let containers = try parser.populateContainers() {
                ctx.debugLog.printParsedTree(for: containers)
                
                ctx.debugLog.templateExecutionStarting()
                
                if let body = try containers.execute(with: ctx) {
                    return body
                }
            }
        } catch let err {
            if let parseErr = err as? TemplateSoup_ParsingError {
                //as the multiblock is proccessed separately, getting current line will not work for that; so lineNo is passed along
                if case let .invalidMultiBlockStmt(lineNo, _) = parseErr {
                    throw ParsingError.invalidLine(lineNo, parseErr.info,  identifier, parseErr)
                } else {
                    throw ParsingError.invalidLine(parser.lineParser.curLineNoForDisplay, parseErr.info,  identifier, parseErr)
                }
            } else if let evalErr = err as? TemplateSoup_EvaluationError {
                if case let .workingDirectoryNotSet(lineNo) = evalErr {
                    throw EvaluationError.workingDirectoryNotSet(lineNo, identifier)
                } else {
                    throw EvaluationError.invalidLine(parser.lineParser.curLineNoForDisplay, evalErr.info,  identifier, evalErr)
                }
            } else {
                throw err
            }
        }
        
        return nil
    }
    
}
 
public protocol TemplateSoupEvaluator {
    func execute(template: Template, context ctx: Context) throws -> String?
}
