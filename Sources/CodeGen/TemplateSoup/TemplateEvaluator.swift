//
// TemplateEvaluator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TemplateEvaluator: TemplateSoupEvaluator {
    
    public func execute(template: Template, context ctx: Context) throws -> String? {
        let contents = template.toString()

        let parser = FileTemplateParser(context: ctx)

        do {
            
            ctx.debugLog.templateParsingStarting()
            
            if let containers = try parser.parse(string: contents, with: ctx) {
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
                    throw ParsingError.invalidLine(lineNo, parseErr.info, parseErr)
                } else {
                    throw ParsingError.invalidLine(parser.lineParser.curLineNoForDisplay, parseErr.info, parseErr)
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
