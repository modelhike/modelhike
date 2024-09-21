//
// ConfigFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ConfigFileParser {
    public func parse(file: LocalFile, with ctx: Context) throws {
        let content = try file.readTextContents()
        try self.parse(string: content, with: ctx)
    }
    
    public func parse(string content: String, with ctx: Context) throws {
        let lineParser = LineParser(string: content, with: ctx)
        
        let curLine = lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            try FrontMatter (lineParser: lineParser, with: ctx)
        } else {
            //configContents = lineParser.getRemainingLinesAsString()
        }
    }
    
    public init() {
        
    }
}
