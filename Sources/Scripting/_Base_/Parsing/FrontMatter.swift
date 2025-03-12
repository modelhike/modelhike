//
//  FrontMatter.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct FrontMatter {
    private let lines: [String]
    private let parser: LineParser
    private let ctx: Context
    private let pInfo: ParsedInfo
    
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
        let curPInfo = pInfo
        var index = 1 // front matter starts after the separator (---) line

        for line in lines {
            curPInfo.line = line
            curPInfo.lineNo = index
            
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()

                if let firstChar = lhs.first {
                    switch firstChar {
                    case "/" : try processCondition(lhs: lhs, rhs: rhs, pInfo: curPInfo)
                    default: setVariablesToMemory(lhs: lhs, rhs: rhs)
                    }
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line, curPInfo)
            }
            
            index += 1
        }
        
    }
    
    private func processCondition(lhs: String, rhs: String, pInfo: ParsedInfo) throws {
        let directiveName = lhs.dropFirst().lowercased()
        
        switch directiveName {
            case ParserDirective.includeIf :
            //if let pInfo = parser.currentParsedInfo(level: 0) {
                let result = try ctx.evaluateCondition(expression: rhs, with: pInfo)
                if !result {
                    throw ParserDirective.excludeFile(parser.identifier)
                }
            //}
                
            case ParserDirective.includeFor:
                //handled elsewhere
                break
            case ParserDirective.outputFilename:
                //handled elsewhere
                break
            default:
            throw ParsingError.unrecognisedParsingDirective(String(directiveName), pInfo)
        }
    }
    
    private func setVariablesToMemory(lhs: String, rhs: String) {
        ctx.variables[lhs] = rhs
    }
    
    public func rhs(for lhsValueToCheck: String) throws -> String? {
        let curPInfo = pInfo
        var index = 1 // front matter starts after the separator (---) line
        
        for line in lines {
            curPInfo.line = line
            curPInfo.lineNo = index
            
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()
                
                if lhs == lhsValueToCheck {
                    return rhs
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line, curPInfo)
            }
            
            index += 1
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
        
        self.pInfo = ParsedInfo.dummy(line: "FrontMatter", identifier: lineParser.identifier, with: context)
    }
    
    @discardableResult
    public init?(in contents: String, filename: String, with context: GenerationContext) throws {
        let lineParser = LineParserDuringGeneration(
            string: contents, identifier: filename, isStatementsPrefixedWithKeyword: true,
            with: context)
        
        parser = lineParser
        ctx = context
        
        let curLine = lineParser.currentLine()

        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            lineParser.skipLine()
            self.lines = lineParser.parseLinesTill(lineHasOnly: TemplateConstants.frontMatterIndicator)
            lineParser.skipLine()
            
            self.pInfo = ParsedInfo.dummy(line: "FrontMatter", identifier: lineParser.identifier, with: context)
        } else {
            return nil
        }
    }
}
