//
// DomainObjectParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum DomainObjectParser {
    // Domain Object starting should be of the format:
    //
    // class name (attributes)
    // ===
    public static func canParse(parser lineParser: LineParser) -> Bool {
        if let nextFirstWord = lineParser.nextLine().firstWord() {
            if nextFirstWord.hasOnly(ModelConstants.NameUnderlineChar) {
                return true
            }
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> DomainObject? {
        let line = parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.className_Capturing)                                                                                  else { return nil }
        
        let (_, className, attributeString, tagString) = match.output
        let item = DomainObject(name: className.trim())
        
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

            if Property.canParse(firstWord: pctx.firstWord) {
                if let prop = try Property.parse(with: pctx) {
                    item.append(prop)
                    continue
                } else {
                    throw Model_ParsingError.invalidPropertyLine(pctx.line)
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
