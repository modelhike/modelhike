//
//  ModuleParser.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum ModuleParser {
    // Module start should be of the format: (minimum three '=' as prefix and suffix
    //
    // === module name (attributes) ===
    public static func canParse(parser lineParser: LineParser) -> Bool {
        let currentLine = lineParser.currentLine()
        
        if let currentFirstWord = currentLine.firstWord(),
           let currentLastWord = currentLine.lastWord() {
            
            if !currentFirstWord.hasOnly(3, of: ModelConstants.NameOverlineChar) {
                return false
            }
            
            if !currentLastWord.hasOnly(ModelConstants.NameOverlineChar) {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: LoadContext) throws -> C4Component? {
        let line = parser.currentLine().dropFirstAndLastWords()
        guard let match = line.wholeMatch(of: ModelRegEx.moduleName_Capturing)                                                                                  else { return nil }
        
        let (_, moduleName, attributeString, tagString) = match.output
        let item = C4Component(name: moduleName)
        
        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: item, from: tagString)
        }
        
        parser.skipLine()//skip module name
        
        return item
    }
}
