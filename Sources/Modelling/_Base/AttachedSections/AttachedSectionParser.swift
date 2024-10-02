//
// AttachedSectionParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension HasAttachedSections
{
    func tryParseAttachedSections(with pctx: ParsingContext) throws -> Bool {
        if AttachedSectionParser.canParse(firstWord: pctx.firstWord) {
            if let section = try AttachedSectionParser.parse(with: pctx) {
                self.attachedSections[section.name] = section
                return true
            } else {
                throw Model_ParsingError.invalidAttachedSection(pctx.line)
            }
        }
        
        return false
    }
}

public enum AttachedSectionParser {
    // Attached Section start should be of the format:
    //
    // # attached section code
    public static func canParse(firstWord: String) -> Bool {
            
        if firstWord.isOnly(ModelConstants.AttachedSection) {
            return true
        }
        
        return false
    }
    
    public static func parse(with pctx: ParsingContext) throws -> AttachedSection? {
        let line = pctx.line.dropFirstWord()
        guard let match = line.wholeMatch(of: ModelRegEx.moduleName_Capturing)                                                                                  else { return nil }
        
        let (_, sectionCode, attributeString, tagString) = match.output
        let item = AttachedSection(code: sectionCode.trim())
        
        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: item, from: tagString)
        }
        
        let parser = pctx.parser
        parser.skipLine()//skip attached section name
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmptyOrCommented() { parser.skipLine(); continue }
            
            guard let pctx = parser.currentParsingContext() else { parser.skipLine(); continue }
            
            if try item.tryParseAnnotations(with: pctx) {
                continue
            }
            
            if pctx.firstWord == ModelConstants.AttachedSection {
                //either it is the starting of another attached section
                // or it is the end of this attached sections, which is
                // having only '#' in the line
                
                if pctx.line.secondWord() == nil { //marks end of attached section
                    parser.skipLine()
                }
                
                break
            }
            
            item.append(pctx.line)
            parser.skipLine()
        }
        
        return item
    }
}
