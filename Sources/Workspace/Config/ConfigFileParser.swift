//
// ConfigFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ConfigFileParser {
    public func parse(file: LocalFile, with ctx: Context) throws {
        let content = try file.readTextContents()
        try self.parse(string: content, identifier: file.name, with: ctx)
    }
    
    public func parse(string content: String, identifier: String, with ctx: Context) throws {
        let lineParser = LineParser(string: content, identifier: identifier, with: ctx)
        
        let curLine = lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            let frontMatter = try FrontMatter (lineParser: lineParser, with: ctx)
            try frontMatter.processVariables()
        } else {
            //configContents = lineParser.getRemainingLinesAsString()
        }
    }
    
    public init() {
        
    }
}
