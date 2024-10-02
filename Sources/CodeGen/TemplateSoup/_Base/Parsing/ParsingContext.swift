//
// ParsingContext.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ParsingContext {
    public internal(set) var line: String
    public internal(set) var firstWord: String
    public internal(set) var parser: LineParser

    public func parseAttachedItems(for item: AttachedSection) throws -> [Artifact] {
        if item.name.lowercased() == "apis" {
            return try APISectionParser.parse(lineParser: self.parser, identifier: item.name)
        }
        
        return []
    }
    
    public func tryParseAttachedSections(with item: HasAttachedSections) throws -> Bool {
        if AttachedSectionParser.canParse(firstWord: self.firstWord) {
            if let section = try AttachedSectionParser.parse(for: item, with: self) {
                item.attachedSections[section.name] = section
                return true
            } else {
                throw Model_ParsingError.invalidAttachedSection(self.line)
            }
        }
        
        return false
    }
    
    public func tryParseAnnotations(with item: HasAnnotations) throws -> Bool {
        if AnnotationParser.canParse(firstWord: self.firstWord) {
            if let annotation = try AnnotationParser.parse(self.line, firstWord: self.firstWord) {
                item.annotations[annotation.name] = annotation
                self.parser.skipLine()
                return true
            } else {
                throw Model_ParsingError.invalidAnnotation(self.line)
            }
        }
        
        return false
    }
    
    public init?(parser: LineParser) {
        self.line = parser.currentLine()
        
        guard let firstWord = line.firstWord() else { return nil }
        self.firstWord = firstWord
        self.parser = parser
    }
}
