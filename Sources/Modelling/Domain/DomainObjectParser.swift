//
//  DomainObjectParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum DomainObjectParser {
    // Domain Object starting should be of the format:
    //
    // class name (attributes)
    // ===
    public static func canParse(parser lineParser: LineParser) async -> Bool {
        if let nextFirstWord = await lineParser.nextLine().firstWord() {
            if nextFirstWord.hasOnly(ModelConstants.NameUnderlineChar) {
                return true
            }
        }

        return false
    }

    public static func parse(parser: LineParser, with pInfo: ParsedInfo) async throws -> DomainObject? {
        let line = await parser.currentLine()

        guard let match = line.wholeMatch(of: ModelRegEx.className_Capturing) else { return nil }

        let (_, className, attributeString, tagString) = match.output

        try await pInfo.ctx.events.onParse(objectName: className, with: pInfo)

        let item = DomainObject(name: className.trim())

        //check if has attributes
        if let attributeString = attributeString {
            await ParserUtil.populateAttributes(for: item, from: attributeString)
        }

        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: item, from: tagString)
        }

        await parser.skipLine(by: 2)  //skip class name and underline

        while await parser.linesRemaining {
            if await parser.isCurrentLineEmptyOrCommented() {
                await parser.skipLine()
                continue
            }

            // Method check before humane-comment: signatures look like plain identifiers
            if await MethodObject.canParse(parser: parser) {
                guard let methodPInfo = await parser.currentParsedInfo(level: 0) else {
                    await parser.skipLine()
                    continue
                }
                if let method = try await MethodObject.parse(pInfo: methodPInfo) {
                    await item.append(method)
                    continue
                } else {
                    throw Model_ParsingError.invalidMethodLine(methodPInfo)
                }
            }

            guard let pInfo = await parser.currentParsedInfo(level: 0) else {
                await parser.skipLine()
                continue
            }
            if await parser.isCurrentLineHumaneComment(pInfo) {
                await parser.skipLine()
                continue
            }  //humane comment

            if Property.canParse(firstWord: pInfo.firstWord) {
                if let prop = try await Property.parse(pInfo: pInfo) {
                    await item.append(prop)
                    continue
                } else {
                    throw Model_ParsingError.invalidPropertyLine(pInfo)
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
