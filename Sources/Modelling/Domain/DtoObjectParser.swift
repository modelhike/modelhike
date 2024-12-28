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
    
    public static func parse(parser: LineParser, with pInfo: ParsedInfo) throws -> DtoObject? {
        let line = parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.className_Capturing)                                                                                  else { return nil }
        
        let (_, className, attributeString, tagString) = match.output
        
        try pInfo.ctx.events.onParse(objectName: className, with: pInfo)

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

            guard let pInfo = parser.currentParsedInfo(level : 0) else { parser.skipLine(); continue }
            if parser.isCurrentLineHumaneComment(pInfo) { parser.skipLine(); continue } //humane comment

            if DerivedProperty.canParse(firstWord: pInfo.firstWord) {
                if let prop = try DerivedProperty.parse(pInfo: pInfo) {
                    item.append(prop)
                    continue
                } else {
                    let msg = pInfo.line
                    throw Model_ParsingError.invalidDerivedProperty(msg, pInfo)
                }
            }
            
            if MethodObject.canParse(firstWord: pInfo.firstWord) {
                if let method = try MethodObject.parse(pInfo: pInfo) {
                    item.append(method)
                    continue
                } else {
                    throw Model_ParsingError.invalidMethodLine(pInfo)
                }
            }
            
            if try pInfo.tryParseAnnotations(with: item) {
                continue
            }
            
            if try pInfo.tryParseAttachedSections(with: item) {
                continue
            }
            
            //nothing can be recognised by this
            break
        }
        
        return item
    }
}
