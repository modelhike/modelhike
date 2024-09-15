//
// ModuleParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
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
            
            if !currentFirstWord.hasOnly(ModelConstants.NameOverlineChar) {
                return false
            }
            
            if !currentLastWord.hasOnly(ModelConstants.NameUnderlineChar) {
                return false
            }
            
            return true
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> C4Component? {
        let line = parser.currentLine()
        let containerName = line.dropFirstAndLastWords()
        let item = C4Component(name: containerName)
        parser.skipLine()//skip module name
        
        return item
    }
}
