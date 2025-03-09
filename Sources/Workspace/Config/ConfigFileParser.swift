//
// ConfigFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ConfigFileParser {
    let ctx: LoadContext
    
    public func parse(file: LocalFile) throws {
        let content = try file.readTextContents()
        try self.parse(string: content, identifier: file.name)
    }
    
    public func parse(string content: String, identifier: String) throws {
        let lineParser = LineParserDuringLoad(string: content, identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        
        let curLine = lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            let frontMatter = try FrontMatter (lineParser: lineParser, with: ctx)
            try frontMatter.processVariables()
        } else {
            //configContents = lineParser.getRemainingLinesAsString()
        }
    }
    
    public init(with ctx: LoadContext) {
        self.ctx = ctx
    }
}
