//
//  ContainerParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum ContainerParser {
    // Container start should be of the format:
    //
    // ===
    // container name (attributes)
    // ===
    public static func canParse(parser lineParser: LineParser) async -> Bool {
        let currentLine = await lineParser.currentLine()
        let nextNextLine = await lineParser.lookAheadLine(by: 2)
            
        if !currentLine.hasOnly(ModelConstants.NameOverlineChar) {
            return false
        }
        
        if !nextNextLine.hasOnly(ModelConstants.NameUnderlineChar) {
            return false
        }
        
        return true
    }
    
    public static func parse(parser: LineParser, with ctx: LoadContext) async throws -> C4Container? {
        await parser.skipLine() //skip the overline
        let line = await parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.containerName_Capturing)                                                                                  else { return nil }
        
        let (_, containerName, attributeString, tagString) = match.output
        let item = await C4Container(name: containerName)
        
        //check if has attributes
        if let attributeString = attributeString {
            await ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: item, from: tagString)
        }
        
        await parser.skipLine(by: 2)//skip container name and underline
        
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }
            
            guard let pInfo = await parser.currentParsedInfo(level: 0) else { await parser.skipLine(); continue }
            if await parser.isCurrentLineHumaneComment(pInfo) { await parser.skipLine(); continue } //humane comment
            
            if ContainerModuleMember.canParse(firstWord: pInfo.firstWord) {
                if let member = try await ContainerModuleMember.parse(with: pInfo) {
                    await item.append(unResolved: member)
                    continue
                } else {
                    throw Model_ParsingError.invalidContainerMemberLine(pInfo)
                }
            }
            
            if try await pInfo.tryParseAnnotations(with: item) {
                continue
            }
            
            if await MethodObject.canParse(parser: parser) {
                guard let methodPInfo = await parser.currentParsedInfo(level: 0) else {
                    await parser.skipLine(); continue
                }
                if let method = try await MethodObject.parse(pInfo: methodPInfo) {
                    await item.append(method)
                    continue
                } else {
                    throw Model_ParsingError.invalidMethodLine(methodPInfo)
                }
            }
            
            //nothing can be recognised by this
            break
        }
        
        return item
    }
}
