//
//  DtoObjectParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum DtoObjectParser {
    // Dto Object starting should be of the format:
    //
    // class name (attributes)
    // /======/
    public static func canParse(parser lineParser: LineParser) async -> Bool {
        let nextLine = await lineParser.nextLine()
        if nextLine.has(prefix: "/", filler: ModelConstants.NameUnderlineChar, suffix: "/") {
            return true
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with pInfo: ParsedInfo) async throws -> DtoObject? {
        let line = await parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.className_Capturing)                                                                                  else { return nil }
        
        let (_, className, attributeString, tagString) = match.output
        
        try await pInfo.ctx.events.onParse(objectName: className, with: pInfo)

        let item = DtoObject(name: className.trim())

        //check if has attributes
        if let attributeString = attributeString {
            await ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: item, from: tagString)
        }
        
        await parser.skipLine(by: 2)//skip class name and underline
        
        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() { await parser.skipLine(); continue }

            // Method check before humane-comment: signatures look like plain identifiers
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

            guard let pInfo = await parser.currentParsedInfo(level: 0) else { await parser.skipLine(); continue }
            if await parser.isCurrentLineHumaneComment(pInfo) { await parser.skipLine(); continue }

            if DerivedProperty.canParse(firstWord: pInfo.firstWord) {
                if let prop = try await DerivedProperty.parse(pInfo: pInfo) {
                    await item.append(prop)
                    continue
                } else {
                    let msg = pInfo.line
                    throw Model_ParsingError.invalidDerivedProperty(msg, pInfo)
                }
            }
            
            if try await pInfo.tryParseAnnotations(with: item) {
                continue
            }
            
            if try await pInfo.tryParseAttachedSections(with: item) {
                continue
            }
            
            //nothing can be recognised by this
            break
        }
        
        return item
    }

}
