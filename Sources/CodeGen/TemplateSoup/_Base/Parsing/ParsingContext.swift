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

    public func parseAttachedItems(for obj: ArtifactContainer, with item: AttachedSection) throws -> [Artifact] {
        if item.name.lowercased() == "apis" {
            return try APISectionParser.parse(for: obj, lineParser: self.parser)
        }
        
        return []
    }
    
    public func tryParseAttachedSections(with item: ArtifactContainerWithAttachedSections) throws -> Bool {
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
    
    public func parseAnnotation(with item: HasAnnotations) throws -> (any Annotation)? {
        if AnnotationParser.canParse(firstWord: self.firstWord) {
            if let annotation = try AnnotationParser.parse(self.line, firstWord: self.firstWord) {
                item.annotations[annotation.name] = annotation
                try AnnotationProcessor.process(annotation, for: item, with: self)
                self.parser.skipLine()
                return annotation
            } else {
                throw Model_ParsingError.invalidAnnotation(self.line)
            }
        }
        
        return nil
    }
    
    public func tryParseAnnotations(with item: HasAnnotations) throws -> Bool {
        if let _ = try parseAnnotation(with: item) {
            return true
        } else {
            return false
        }
    }
    
    public init?(parser: LineParser) {
        self.line = parser.currentLine()
        
        guard let firstWord = line.firstWord() else { return nil }
        self.firstWord = firstWord
        self.parser = parser
    }
}
