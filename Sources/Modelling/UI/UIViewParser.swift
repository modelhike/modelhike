//
// DtoObjectParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum UIViewParser {
    // UI View starting should be of the format:
    //
    // ui view name (attributes)
    // ~~~~~~~~~~~~~~
    public static func canParse(parser lineParser: LineParser) -> Bool {
        if let nextFirstWord = lineParser.nextLine().firstWord() {
            if nextFirstWord.hasOnly(ModelConstants.UIViewUnderlineChar) {
                return true
            }
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> UIView? {
        let line = parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.uiviewName_Capturing)                                                                                  else { return nil }
        
        let (_, className, attributeString, tagString) = match.output
        let item = UIView(name: className.trim())
        
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
            
            guard let pctx = parser.currentParsedInfo(level : 0) else { parser.skipLine(); continue }

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
