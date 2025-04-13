//
//  UIViewParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum UIViewParser {
    // UI View starting should be of the format:
    //
    // ui view name (attributes)
    // ~~~~~~~~~~~~~~
    public static func canParse(parser lineParser: LineParser) async -> Bool {
        if let nextFirstWord = await lineParser.nextLine().firstWord() {
            if nextFirstWord.hasOnly(ModelConstants.UIViewUnderlineChar) {
                return true
            }
        }

        return false
    }

    public static func parse(parser: LineParser, with ctx: LoadContext) async throws -> UIView? {
        let line = await parser.currentLine()

        guard let match = line.wholeMatch(of: ModelRegEx.uiviewName_Capturing)                                                                                  else { return nil }

        let (_, className, attributeString, tagString) = match.output
        let item = UIView(name: className.trim())

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

            guard let pctx = await parser.currentParsedInfo(level : 0) else { await parser.skipLine(); continue }

            if try await pctx.tryParseAnnotations(with: item) {
                continue
            }

            if try await pctx.tryParseAttachedSections(with: item) {
                continue
            }

            //nothing can be recognised by this
            break
        }

        return item
    }
}
