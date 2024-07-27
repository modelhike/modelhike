//
// DomainObjectParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum DomainObjectParser {
    public static func canParse(parser lineParser: LineParser) -> Bool {
        if let nextFirstWord = lineParser.nextLine().firstWord() {
            if nextFirstWord.starts(with: "===") {
                return true
            }
        }
        
        return false
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> DomainObject? {
        let className = parser.currentLine()
        let item = DomainObject(className)
        parser.skipLine(by: 2)//skip class name and underline
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmpty() { break }
            
            let line = parser.currentLine()
            
            guard let firstWord = line.firstWord() else { parser.skipLine(); continue }
            
            if Property.canParse(firstWord: firstWord) {
                if let prop = try Property.parse(line, firstWord: firstWord) {
                    item.append(prop)
                    parser.skipLine()
                    continue
                } else {
                    throw Model_ParsingError.invalidPropertyLine(line)
                }
            }
            
            if AnnotationParser.canParse(firstWord: firstWord) {
                if let annotation = try AnnotationParser.parse(line, firstWord: firstWord) {
                    item.annotations[annotation.name] = annotation
                    parser.skipLine()
                    continue
                }
            }
            
            parser.skipLine()
        }
        
        return item
    }
}
