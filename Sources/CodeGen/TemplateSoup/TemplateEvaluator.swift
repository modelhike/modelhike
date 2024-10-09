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
            let curLine = lineParser.currentLine()
            
            if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
                let frontMatter = try FrontMatter (lineParser: lineParser, with: ctx)
                try frontMatter.processVariables()
            }
            
            ctx.debugLog.templateParsingStarting()
            
            if let containers = try parser.populateContainers() {
                ctx.debugLog.printParsedTree(for: containers)
                
                ctx.debugLog.templateExecutionStarting()
                
                if let body = try containers.execute(with: ctx) {
                    return body
                }
            }
        } catch let err {
            let identifier = lineParser.identifier
            if let parseErr = err as? TemplateSoup_ParsingError {
                //as the multiblock is proccessed separately, getting current line will not work for that; so lineNo is passed along
                if case let .invalidMultiBlockStmt(lineNo, _) = parseErr {
                    throw ParsingError.invalidLine(lineNo, identifier, parseErr.info, parseErr)
                } else if case let .modifierInvalidArguments(lineNo, _) = parseErr {
                    throw ParsingError.invalidLine(lineNo, identifier, parseErr.info, parseErr)
                } else if case let .invalidExpression(lineNo, _) = parseErr {
                        throw ParsingError.invalidLine(lineNo, identifier, parseErr.info, parseErr)
                } else if case let .invalidPropertyNameUsedInCall(lineNo, _) = parseErr {
                        throw ParsingError.invalidLine(lineNo, identifier, parseErr.info, parseErr)
                } else if case let .templateFunctionNotFound(lineNo, _) = parseErr {
                    throw ParsingError.invalidLine(lineNo, identifier, parseErr.info, parseErr)
                } else {
                    throw ParsingError.invalidLine(parser.lineParser.curLineNoForDisplay, identifier, parseErr.info, parseErr)
                }
            } else if let evalErr = err as? TemplateSoup_EvaluationError {
                if case let .workingDirectoryNotSet(lineNo) = evalErr {
                    throw EvaluationError.workingDirectoryNotSet(lineNo, identifier)
                } else if case .unIdentifiedStmt(_, _) = evalErr {
                    throw EvaluationError.invalidLineWithInfo_HavingLineno(identifier, evalErr.info, evalErr)
                } else {
                    throw EvaluationError.invalidLine(parser.lineParser.curLineNoForDisplay, identifier, evalErr.info,   evalErr)
                }
            } else if let directive = err as? ParserDirectives {
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
