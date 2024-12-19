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
        let line = parser.currentLine()
        
        guard let match = line.wholeMatch(of: ModelRegEx.containerName_Capturing)                                                                                  else { return nil }
        
        let (_, containerName, attributeString, tagString) = match.output
        let item = C4Container(name: containerName)
        
        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: item, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: item, from: tagString)
        }
        
        parser.skipLine(by: 2)//skip container name and underline
        
        while parser.linesRemaining {
            if parser.isCurrentLineEmptyOrCommented() { parser.skipLine(); continue }
            
            guard let pctx = parser.currentParsedInfo(level: 0) else { parser.skipLine(); continue }
            if parser.isCurrentLineHumaneComment(pctx) { parser.skipLine(); continue } //humane comment
            
            if ContainerModuleMember.canParse(firstWord: pctx.firstWord) {
                if let member = try ContainerModuleMember.parse(with: pctx) {
                    item.append(unResolved: member)
                    continue
                } else {
                    throw Model_ParsingError.invalidContainerMemberLine(pctx.line)
                }
            }
            
            if try pctx.tryParseAnnotations(with: item) {
                continue
            }
            
            if MethodObject.canParse(firstWord: pctx.firstWord) {
                if let method = try MethodObject.parse(with: pctx) {
                    item.append(method)
                    continue
                } else {
                    throw Model_ParsingError.invalidMethodLine(pctx.line)
                }
            }
            
            //nothing can be recognised by this
            break
        }
        
        return item
    }
}
