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
        return try self.parse(lines: lines, identifier: file.name, with: ctx)
    }
    
    public func parse(string: String, identifier: String, with ctx: Context) throws -> ModelSpace {
        let lines = string.components(separatedBy: .newlines)
        return try self.parse(lines: lines, identifier: identifier, with: ctx)
    }
    
    public func parse(lines contents: [String], identifier: String, with ctx: Context) throws -> ModelSpace {
        let lineParser = LineParser(lines: contents, with: ctx, autoIncrementLineNoForEveryLoop: false)
        self.lineParser = lineParser

        do {
            
            try lineParser.parse() {firstWord, secondWord, line, ctx in
                if lineParser.isCurrentLineEmpty() { lineParser.skipLine(); return }

                if ContainerParser.canParse(parser: lineParser) {
                    try parseContainer(firstWord: firstWord, line: line, parser: lineParser)
                    return
                }
                
                if ModuleParser.canParse(parser: lineParser) {
                    try parseModule(firstWord: firstWord, line: line, parser: lineParser)
                    return
                }
                
                if SubModuleParser.canParse(parser: lineParser) {
                    try parseSubModule(firstWord: firstWord, line: line, parser: lineParser)
                    return
                }
                
                //check for class starting
                if DomainObjectParser.canParse(parser: lineParser) {
                    if let item = try DomainObjectParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                        return
                    }
                }
                
                if DtoObjectParser.canParse(parser: lineParser) {
                    if let item = try DtoObjectParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                        return
                    }
                }
                
                if UIViewParser.canParse(parser: lineParser) {
                    if let item = try UIViewParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                        return
                    }
                }
                
                lineParser.skipLine();
            }
            
            return modelSpace
        } catch let err {
            if let parseErr = err as? Model_ParsingError {
                throw ParsingError.invalidLine(self.lineParser.curLineNoForDisplay, parseErr.info, identifier, parseErr)
            } else {
                throw err
            }
        }
    }
    
    func parseModule(firstWord: String, line: String, parser: LineParser) throws {
        if let module = try ModuleParser.parse(parser: lineParser, with: ctx) {
            self.component = module
            self.modelSpace.append(module: module)
        } else {
            throw Model_ParsingError.invalidModuleLine(line)
        }
    }
    
    func parseSubModule(firstWord: String, line: String, parser: LineParser) throws {
        if let submodule = try SubModuleParser.parse(parser: lineParser, with: ctx) {
            self.component.append(submodule: submodule)
        } else {
            throw Model_ParsingError.invalidSubModuleLine(line)
        }
    }
    
    func parseContainer(firstWord: String, line: String, parser: LineParser) throws {
        if let container = try ContainerParser.parse(parser: lineParser, with: ctx) {
            self.modelSpace.append(container: container)
        } else {
            throw Model_ParsingError.invalidContainerLine(line)
        }
    }
    
    public init(with context: Context) {
        lineParser = LineParser(context: context)
        self.ctx = context
    }
}
