//
// ContainerParser.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ContainerParser {
    // Container start should be of the format:
    //
    // ===
    // container name (attributes)
    // ===
    public static func canParse(parser lineParser: LineParser) -> Bool {
        let currentLine = lineParser.currentLine()
        let nextNextLine = lineParser.lookAheadLine(by: 2)
            
        if !currentLine.hasOnly(ModelConstants.NameOverlineChar) {
            return false
        }
        
        if !nextNextLine.hasOnly(ModelConstants.NameUnderlineChar) {
            return false
        }
        
        return true
    }
    
    public static func parse(parser: LineParser, with ctx: Context) throws -> C4Container? {
        parser.skipLine() //skip the overline
        let containerName = parser.currentLine()
        let item = C4Container(name: containerName)
        parser.skipLine(by: 2)//skip container name and underline
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmpty() { break }
            
            let line = parser.currentLine()
            
            guard let firstWord = line.firstWord() else { parser.skipLine(); continue }
            
            if ContainerModuleMember.canParse(firstWord: firstWord) {
                if let member = try ContainerModuleMember.parse(line, firstWord: firstWord) {
                    item.append(unResolved: member)
                    parser.skipLine()
                    continue
                } else {
                    throw Model_ParsingError.invalidContainerMemberLine(line)
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
