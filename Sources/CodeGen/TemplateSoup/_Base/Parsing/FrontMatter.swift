//
// FrontMatter.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct FrontMatter {
    private let lines: [String]
    private let parser: LineParser
    private let ctx: Context
    
    public func hasDirective(_ directive: String) -> ParsedInfo? {
        do {
            let directiveString = "/\(directive)"
            if let rhs = try self.rhs(for: directiveString) {
                return ParsedInfo(parser: parser, line: rhs, lineNo: -1, level: 0, firstWord: directiveString)
            }
            
            return nil
        } catch {
            return nil
        }
        
    }
    
    public func evalDirective(_ directive: String, pInfo: ParsedInfo) throws -> Any? {
        let directiveString = "/\(directive)"
        if let rhs = try self.rhs(for: directiveString) {
            return try ContentHandler.eval(line: rhs, pInfo: pInfo)
        }
        return nil
    }
    
    public func processVariables() throws {
        
        for line in lines {
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()

                if let firstChar = lhs.first {
                    switch firstChar {
                        case "/" : try processCondition(lhs: lhs, rhs: rhs)
                        default: setVariablesToMemory(lhs: lhs, rhs: rhs)
                    }
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line)
            }
        }
        
    }
    
    private func processCondition(lhs: String, rhs: String) throws {
        let directiveName = lhs.dropFirst().lowercased()
        
        switch directiveName {
            case ParserDirectives.includeIf :
            if let pInfo = parser.currentParsedInfo(level: 0) {
                let result = try ctx.evaluateCondition(expression: rhs, pInfo: pInfo)
                if !result {
                    throw ParserDirectives.excludeFile(parser.identifier)
                }
            }
                
            case ParserDirectives.includeFor:
                //handled elsewhere
                break
            case ParserDirectives.outputFilename:
                //handled elsewhere
                break
            default:
                throw ParsingError.unrecognisedParsingDirective(parser.curLineNoForDisplay, parser.identifier, String(directiveName))
        }
    }
    
    private func setVariablesToMemory(lhs: String, rhs: String) {
        ctx.variables[lhs] = rhs
    }
    
    public func rhs(for lhsValueToCheck: String) throws -> String? {
        for line in lines {
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()
                
                if lhs == lhsValueToCheck {
                    return rhs
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line)
            }
        }
        
        return nil
    }
    
    @discardableResult
    public init(lineParser: LineParser, with context: Context) throws {
        parser = lineParser
        ctx = context
        
        lineParser.skipLine()
        self.lines = lineParser.parseLinesTill(lineHasOnly: TemplateConstants.frontMatterIndicator)
        lineParser.skipLine()
    }
}
