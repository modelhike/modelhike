//
//  ConfigFileParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ConfigFileParser {
    let ctx: LoadContext
    
    public func parse(file: LocalFile) async throws {
        let content = try file.readTextContents()
        try await self.parse(string: content, identifier: file.name)
    }
    
    public func parse(string content: String, identifier: String) async throws {
        let lineParser = LineParserDuringLoad(string: content, identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        
        let curLine = await lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            var frontMatter = try await FrontMatter (lineParser: lineParser, with: ctx)
            try await frontMatter.processVariables()
        } else {
            //configContents = lineParser.getRemainingLinesAsString()
        }
    }
    
    public init(with ctx: LoadContext) {
        self.ctx = ctx
    }
}
