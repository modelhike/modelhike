//
//  ModelFileParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ModelFileParser {
    let modelSpace = ModelSpace()
    var component = C4Component()
    var subComponent : C4Component?
    var lineParser : LineParserDuringLoad
    let ctx: LoadContext
    
    public func parse(file: LocalFile) async throws -> ModelSpace {
        let lines = try file.readTextLines(ignoreEmptyLines: true)
        return try await self.parse(lines: lines, identifier: file.name)
    }
    
    public func parse(string: String, identifier: String) async throws -> ModelSpace {
        let lines = string.splitIntoLines()
        return try await self.parse(lines: lines, identifier: identifier)
    }
    
    public func parse(lines contents: [String], identifier: String) async throws -> ModelSpace {
        let lineParser = LineParserDuringLoad(lines: contents, identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx, autoIncrementLineNoForEveryLoop: false)
        self.lineParser = lineParser

        do {
            
            try await lineParser.parse(level: 0) {[weak self] pctx, _ in
                guard let self else { return }
                
                if await lineParser.isCurrentLineEmptyOrCommented() { await lineParser.skipLine(); return }

                guard let pInfo = await lineParser.currentParsedInfo(level : pctx.level) else { await lineParser.skipLine(); return }

                if await ContainerParser.canParse(parser: lineParser) {
                    try await self.parseContainer(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                if await ModuleParser.canParse(parser: lineParser) {
                    try await parseModule(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                if await SubModuleParser.canParse(parser: lineParser) {
                    try await parseSubModule(firstWord: pInfo.firstWord, pInfo: pInfo, parser: lineParser)
                    return
                }
                
                //check for class starting
                if await DomainObjectParser.canParse(parser: lineParser) {
                    if let item = try await DomainObjectParser.parse(parser: lineParser, with: pInfo) {
                        await appendToComponent(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidDomainObjectLine(pInfo)
                    }
                }
                
                if await DtoObjectParser.canParse(parser: lineParser) {
                    if let item = try await DtoObjectParser.parse(parser: lineParser, with: pInfo) {
                        await appendToComponent(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidDtoObjectLine(pInfo)
                    }
                }
                
                if await UIViewParser.canParse(parser: lineParser) {
                    if let item = try await UIViewParser.parse(parser: lineParser, with: ctx) {
                        await appendToComponent(item)
                        return
                    } else {
                        throw Model_ParsingError.invalidUIViewLine(pInfo)
                    }
                }
                
                if let subComponent = await self.subComponent { //sub module active
                    if try await pInfo.tryParseAnnotations(with: subComponent) {
                        return
                    }
                } else {
                    if try await pInfo.tryParseAnnotations(with: self.component) {
                        return
                    }
                }
                                
                await lineParser.skipLine();
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
    
    func parseModule(firstWord: String, pInfo: ParsedInfo, parser: LineParser) async throws {
        if let module = try await ModuleParser.parse(parser: lineParser, with: ctx) {
            self.component = module
            self.subComponent = nil
            await self.modelSpace.append(module: module)
        } else {
            throw Model_ParsingError.invalidModuleLine(pInfo)
        }
    }
    
    func parseSubModule(firstWord: String, pInfo: ParsedInfo, parser: LineParser) async throws {
        if let submodule = try await SubModuleParser.parse(parser: lineParser, with: ctx) {
            self.subComponent = submodule
            await self.component.append(submodule: submodule)
        } else {
            throw Model_ParsingError.invalidSubModuleLine(pInfo)
        }
    }
    
    func parseContainer(firstWord: String, pInfo: ParsedInfo, parser: LineParser) async throws {
        if let container = try await ContainerParser.parse(parser: lineParser, with: ctx) {
            await self.modelSpace.append(container: container)
        } else {
            throw Model_ParsingError.invalidContainerLine(pInfo)
        }
    }
    
    fileprivate func appendToComponent(_ item: CodeObject) async {
        //if sub-component is actively being parsed, then add the object to it
        if let subComponent = self.subComponent {
            await subComponent.append(item)
        } else {
            await self.component.append(item)
        }
    }
    
    
    fileprivate func appendToComponent(_ item: UIObject) async {
        //if sub-component is actively being parsed, then add the object to it
        if let subComponent = self.subComponent {
            await subComponent.append(item)
        } else {
            await self.component.append(item)
        }
    }
    
    public init(with context: LoadContext) {
        lineParser = LineParserDuringLoad(identifier: "", isStatementsPrefixedWithKeyword: true, with: context)
        self.ctx = context
    }
}
