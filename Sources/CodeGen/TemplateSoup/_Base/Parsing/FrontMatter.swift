//
// FrontMatter.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct FrontMatter {
    private let lines: [String]
    
    @discardableResult
    public init(lineParser: LineParser, with context: Context) throws {
        lineParser.skipLine()
        self.lines = lineParser.parseLinesTill(lineHasOnly: TemplateConstants.frontMatterIndicator)
        lineParser.skipLine()
        
        try setVariablesToMemort(ctx: context)
    }
    
    func setVariablesToMemort(ctx: Context) throws {
        
        for line in lines {
            let split = line.split(separator: TemplateConstants.frontMatterSplit, maxSplits: 1, omittingEmptySubsequences: true)
            if split.count == 2 {
                let lhs = String(split[0]).trim()
                let rhs = String(split[1]).trim()

                ctx.variables[lhs] = rhs
            } else {
                throw TemplateSoup_ParsingError.invalidFrontMatter(line)
            }
        }
        
    }
}
