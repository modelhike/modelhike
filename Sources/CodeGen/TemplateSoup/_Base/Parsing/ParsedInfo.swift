//
// ParsingContext.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ParsedInfo {
    public internal(set) var line: String
    public internal(set) var lineNo: Int
    public internal(set) var level: Int
    public internal(set) var firstWord: String
    public internal(set) var parser: LineParser
    public var ctx: Context { parser.ctx }
    
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
    
    public static func dummy(for line: String, with ctx: Context) -> ParsedInfo {
        let parser = LineParser(with: ctx)
        return ParsedInfo(parser: parser, line: line, lineNo: -1, level: 0, firstWord: "")
    }
    
    public init?(parser: LineParser) {
        //the currentLine() returns a trummed string, which removes prefixed space for content;
        //so, another method, that does not trim prefix, is used
        self.line = parser.currentLine_TrimTrailing()
        self.lineNo = parser.curLineNoForDisplay
        
        guard let firstWord = line.firstWord() else { return nil }
        self.firstWord = firstWord
        self.parser = parser
        self.level = parser.curLevelForDisplay
    }
    
    public init(parser: LineParser, line: String, lineNo: Int, level: Int, firstWord: String) {
        self.line = line
        self.lineNo = lineNo

        self.firstWord = firstWord
        self.parser = parser
        self.level = level
    }
}

public class ParsedContextInfo {
    public var line: String
    public var lineNo: Int
    public var identifier: String
    
    public init(with pctx: ParsedInfo) {
        self.line = pctx.line
        self.lineNo = pctx.parser.curLineNoForDisplay
        self.identifier = pctx.parser.identifier
    }
}
