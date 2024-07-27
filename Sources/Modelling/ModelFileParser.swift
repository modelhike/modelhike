//
// ModelFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ModelFileParser {
    var system = C4System()
    var container = C4Container()
    var component = C4Component()
    var lineParser : LineParser
    let ctx: Context
    
    public func parse(file: LocalFile, with ctx: Context) throws -> C4System {
        let lines = try file.readTextLines(ignoreEmptyLines: true)
        return try self.parse(lines: lines, with: ctx)
    }
    
    public func parse(string: String, with ctx: Context) throws -> C4System {
        let lines = string.components(separatedBy: .newlines)
        return try self.parse(lines: lines, with: ctx)
    }
    
    public func parse(lines contents: [String], with ctx: Context) throws -> C4System {
        let lineParser = LineParser(lines: contents, with: ctx)
        self.lineParser = lineParser

        do {
            
            try lineParser.parse() {firstWord, secondWord, line, ctx in
                
                if firstWord == "#" {
                    parseModule(firstWord: firstWord, parser: lineParser)
                }
                
                //check for class starting
                if DomainObjectParser.canParse(parser: lineParser) {
                    if let item = try DomainObjectParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                    }
                }
                
            }
            
            return system
        } catch let err {
            if let parseErr = err as? Model_ParsingError {
                throw ParsingError.invalidLine(self.lineParser.curLineNoForDisplay, parseErr.info, parseErr)
            } else {
                throw err
            }
        }
    }
    
    func parseModule(firstWord: String, parser: LineParser) {
        let moduleName = parser.currentLine(after: firstWord)
        
        //if the placeholder container is empty, remove it as an actual module is detected
        if self.component.isEmpty && self.container.count == 1 { self.container.removeAll()
        }
        
        //add new module
        self.component = C4Component(name: moduleName)
        self.container.append(component)
    }
    
    public init(with context: Context) {
        lineParser = LineParser(context: context)
        self.ctx = context
        
        container.append(component)
        system.append(container)
    }
}
