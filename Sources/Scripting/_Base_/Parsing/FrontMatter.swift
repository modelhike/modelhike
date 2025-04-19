//
//  FrontMatter.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct FrontMatter: Sendable {
    private let lines: [String]
    private let parser: LineParser
    private let ctx: Context
    private var pInfo: ParsedInfo
    
    public func hasDirective(_ directive: String) async  -> ParsedInfo? {
        do {
            let directiveString = "/\(directive)"
            if let rhs = try self.rhs(for: directiveString) {
                return await ParsedInfo(parser: parser, line: rhs, lineNo: -1, level: 0, firstWord: directiveString)
            }
            
            return nil
        } catch {
            return nil
        }
        
    }
    
    public func evalDirective(_ directive: String, pInfo: ParsedInfo) async throws -> Any? {
        let directiveString = "/\(directive)"
        if let rhs = try self.rhs(for: directiveString) {
            return try await ContentHandler.eval(line: rhs, pInfo: pInfo)
        }
        return nil
    }
    
    public mutating func processVariables() async throws {
        var index = 1 // front matter starts after the separator (---) line

        for line in lines {
            pInfo.setLineInfo(line: line, lineNo: index)
            
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()

                if let firstChar = lhs.first {
                    switch firstChar {
                    case "/" : try await processCondition(lhs: lhs, rhs: rhs, pInfo: pInfo)
                    default: await setVariablesToMemory(lhs: lhs, rhs: rhs)
                    }
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line, pInfo)
            }
            
            index += 1
        }
        
    }
    
    private func processCondition(lhs: String, rhs: String, pInfo: ParsedInfo) async throws {
        let directiveName = lhs.dropFirst().lowercased()
        
        switch directiveName {
            case ParserDirective.includeIf :
            //if let pInfo = parser.currentParsedInfo(level: 0) {
                let result = try await ctx.evaluateCondition(expression: rhs, with: pInfo)
                if !result {
                    throw ParserDirective.excludeFile(await parser.identifier)
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
    
    private func setVariablesToMemory(lhs: String, rhs: String) async {
        await ctx.variables.set(lhs, value: rhs)
    }
    
    public func rhs(for lhsValueToCheck: String) throws -> String? {
        var index = 1 // front matter starts after the separator (---) line
        
        var pInfo2 = pInfo
        for line in lines {
            pInfo2.setLineInfo(line: line, lineNo: index)
            
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()
                
                if lhs == lhsValueToCheck {
                    return rhs
                }
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line, pInfo2)
            }
            
            index += 1
        }
        
        return nil
    }
    
    @discardableResult
    public init(lineParser: LineParser, with context: Context) async throws {
        parser = lineParser
        ctx = context
        
        await lineParser.skipLine()
        self.lines = await lineParser.parseLinesTill(lineHasOnly: TemplateConstants.frontMatterIndicator)
        await lineParser.skipLine()
        
        self.pInfo = await ParsedInfo.dummy(line: "FrontMatter", identifier: lineParser.identifier, with: context)
    }
    
    @discardableResult
    public init?(in contents: String, filename: String, with context: GenerationContext) async throws {
        let lineParser = LineParserDuringGeneration(
            string: contents, identifier: filename, isStatementsPrefixedWithKeyword: true,
            with: context)
        
        parser = lineParser
        ctx = context
        
        let curLine = await lineParser.currentLine()

        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            await lineParser.skipLine()
            self.lines = await lineParser.parseLinesTill(lineHasOnly: TemplateConstants.frontMatterIndicator)
            await lineParser.skipLine()
            
            self.pInfo = await ParsedInfo.dummy(line: "FrontMatter", identifier: await lineParser.identifier, with: context)
        } else {
            return nil
        }
    }
}
