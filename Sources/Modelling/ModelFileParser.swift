//
// ModelFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ModelFileParser {
    var modelSpace = ModelSpace()
    var component = C4Component()
    var lineParser : LineParser
    let ctx: Context
    
    public func parse(file: LocalFile, with ctx: Context) throws -> ModelSpace {
        let lines = try file.readTextLines(ignoreEmptyLines: true)
        return try self.parse(lines: lines, with: ctx)
    }
    
    public func parse(string: String, with ctx: Context) throws -> ModelSpace {
        let lines = string.components(separatedBy: .newlines)
        return try self.parse(lines: lines, with: ctx)
    }
    
    public func parse(lines contents: [String], with ctx: Context) throws -> ModelSpace {
        let lineParser = LineParser(lines: contents, with: ctx)
        self.lineParser = lineParser

        do {
            
            try lineParser.parse() {firstWord, secondWord, line, ctx in
                if lineParser.isCurrentLineEmpty() { return }

                if ContainerParser.canParse(parser: lineParser) {
                    try parseContainer(firstWord: firstWord, parser: lineParser)
                    return
                }
                
                if ModuleParser.canParse(parser: lineParser) {
                    try parseModule(firstWord: firstWord, parser: lineParser)
                    return
                }
                
                //check for class starting
                if DomainObjectParser.canParse(parser: lineParser) {
                    if let item = try DomainObjectParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                        return
                    }
                }
                
            }
            
            return modelSpace
        } catch let err {
            if let parseErr = err as? Model_ParsingError {
                throw ParsingError.invalidLine(self.lineParser.curLineNoForDisplay, parseErr.info, parseErr)
            } else {
                throw err
            }
        }
    }
    
    func parseModule(firstWord: String, parser: LineParser) throws {
        guard let module = try ModuleParser.parse(parser: lineParser, with: ctx) else { return }
        
        self.component = module
        self.modelSpace.append(module: module)
    }
    
    func parseContainer(firstWord: String, parser: LineParser) throws {
        guard let container = try ContainerParser.parse(parser: lineParser, with: ctx) else { return }
        
        self.modelSpace.append(container: container)
    }
    
    public init(with context: Context) {
        lineParser = LineParser(context: context)
        self.ctx = context
    }
}
