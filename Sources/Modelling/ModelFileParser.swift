//
// ModelFileParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ModelFileParser {
    var modelSpace = ModelSpace()
    var component = C4Component()
    var subComponent : C4Component?
    var lineParser : LineParserDuringLoad
    let ctx: LoadContext
    
    public func parse(file: LocalFile) throws -> ModelSpace {
        let lines = try file.readTextLines(ignoreEmptyLines: true)
        return try self.parse(lines: lines, identifier: file.name)
    }
    
    public func parse(string: String, identifier: String) throws -> ModelSpace {
        let lines = string.splitIntoLines()
        return try self.parse(lines: lines, identifier: identifier)
    }
    
    public func parse(lines contents: [String], identifier: String) throws -> ModelSpace {
        let lineParser = LineParserDuringLoad(lines: contents, identifier: identifier, with: ctx, autoIncrementLineNoForEveryLoop: false)
        self.lineParser = lineParser

        do {
            
            try lineParser.parse(level: 0) {pctx, secondWord in
                if lineParser.isCurrentLineEmptyOrCommented() { lineParser.skipLine(); return }

                guard let pInfo = lineParser.currentParsedInfo(level : pctx.level) else { lineParser.skipLine(); return }

                if ContainerParser.canParse(parser: lineParser) {
                    try parseContainer(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                if ModuleParser.canParse(parser: lineParser) {
                    try parseModule(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                if SubModuleParser.canParse(parser: lineParser) {
                    try parseSubModule(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                //check for class starting
                if DomainObjectParser.canParse(parser: lineParser) {
                    if let item = try DomainObjectParser.parse(parser: lineParser, with: pInfo) {
                        self.component.append(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidDomainObjectLine(pInfo)
                    }
                }
                
                if DtoObjectParser.canParse(parser: lineParser) {
                    if let item = try DtoObjectParser.parse(parser: lineParser, with: pInfo) {
                        self.component.append(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidDtoObjectLine(pInfo)
                    }
                }
                
                if UIViewParser.canParse(parser: lineParser) {
                    if let item = try UIViewParser.parse(parser: lineParser, with: ctx) {
                        self.component.append(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidUIViewLine(pInfo)
                    }
                }
                
                if let subComponent = self.subComponent { //sub module active
                    if try pInfo.tryParseAnnotations(with: subComponent) {
                        return
                    }
                } else {
                    if try pInfo.tryParseAnnotations(with: self.component) {
                        return
                    }
                }
                                
                lineParser.skipLine();
            }
            
            return modelSpace
        } catch let err {
            if let parseErr = err as? Model_ParsingError {
                throw ParsingError.invalidLine(parseErr.pInfo, parseErr)
            } else {
                throw err
            }
        }
    }
    
    func parseModule(firstWord: String, pInfo: ParsedInfo, parser: LineParser) throws {
        if let module = try ModuleParser.parse(parser: lineParser, with: ctx) {
            self.component = module
            self.subComponent = nil
            self.modelSpace.append(module: module)
        } else {
            throw Model_ParsingError.invalidModuleLine(pInfo)
        }
    }
    
    func parseSubModule(firstWord: String, pInfo: ParsedInfo, parser: LineParser) throws {
        if let submodule = try SubModuleParser.parse(parser: lineParser, with: ctx) {
            self.subComponent = submodule
            self.component.append(submodule: submodule)
        } else {
            throw Model_ParsingError.invalidSubModuleLine(pInfo)
        }
    }
    
    func parseContainer(firstWord: String, pInfo: ParsedInfo, parser: LineParser) throws {
        if let container = try ContainerParser.parse(parser: lineParser, with: ctx) {
            self.modelSpace.append(container: container)
        } else {
            throw Model_ParsingError.invalidContainerLine(pInfo)
        }
    }
    
    public init(with context: LoadContext) {
        lineParser = LineParserDuringLoad(identifier: "", with: context)
        self.ctx = context
    }
}
