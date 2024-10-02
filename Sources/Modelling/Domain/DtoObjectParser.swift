//
// DtoObjectParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum DtoObjectParser {
    // Dto Object starting should be of the format:
    //
    // class name (attributes)
    // /======/
    public static func canParse(parser lineParser: LineParser) -> Bool {
        let nextLine = lineParser.nextLine()
        if nextLine.has(prefix: "/", filler: ModelConstants.NameUnderlineChar, suffix: "/") {
            return true
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> DtoObject? {
        let line = parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.className_Capturing)                                                                                  else { return nil }
        
        let (_, className, attributeString, tagString) = match.output
        let item = DtoObject(name: className.trim())

        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: item, from: tagString)
        }
        
        parser.skipLine(by: 2)//skip class name and underline
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmptyOrCommented() { parser.skipLine(); continue }

            guard let pctx = parser.currentParsingContext() else { parser.skipLine(); continue }
            if parser.isCurrentLineHumaneComment(pctx) { parser.skipLine(); continue } //humane comment

            if DerivedProperty.canParse(firstWord: pctx.firstWord) {
                if let prop = try DerivedProperty.parse(with: pctx) {
                    item.append(prop)
                    continue
                } else {
                    throw Model_ParsingError.invalidDerivedPropertyLine(pctx.line)
                }
            }
            
            if try pctx.tryParseAnnotations(with: item) {
                continue
            }
            
            if try pctx.tryParseAttachedSections(with: item) {
                continue
            }
            
            //nothing can be recognised by this
            break
        }
        
        return item
    }
}
