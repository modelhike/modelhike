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
    let context: Context
    
    public func parseAttachedItems(for obj: ArtifactHolder, with section: AttachedSection) throws -> [Artifact] {
        if let cls = obj as? CodeObject {
            if section.name.lowercased() == "apis" {
                return try APISectionParser.parse(for: cls, lineParser: self.parser)
            }
        }
        
        return []
    }
    
    public func tryParseAttachedSections(with item: ArtifactHolderWithAttachedSections) throws -> Bool {
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
            if let annotation = try AnnotationParser.parse(with: self) {
                item.annotations[annotation.name] = annotation
                try AnnotationProcessor.process(annotation, for: item)
                self.parser.skipLine()
                return annotation
            } else {
                throw Model_ParsingError.invalidAnnotation(self.parser.curLineNoForDisplay, self.line)
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
        self.context = parser.ctx
    }
    
    public init(parser: LineParser, line: String, firstWord: String) {
        self.line = line
        self.firstWord = firstWord
        self.parser = parser
        self.context = parser.ctx
    }
}

public class ParsedContextInfo {
    public var line: String
    public var lineNo: Int
    public var identifier: String
    
    public init(with pctx: ParsingContext) {
        self.line = pctx.line
        self.lineNo = pctx.parser.curLineNoForDisplay
        self.identifier = pctx.parser.identifier
    }
}
