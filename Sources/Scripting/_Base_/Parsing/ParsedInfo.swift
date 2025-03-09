//
//  ParsingContext.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ParsedInfo : Equatable {
    public internal(set) var line: String
    public internal(set) var lineNo: Int
    public internal(set) var level: Int
    public internal(set) var firstWord: String
    public internal(set) var secondWord: String? = nil

    public internal(set) var identifier: String
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
                throw Model_ParsingError.invalidAttachedSection(self)
            }
        }
        
        return false
    }
    
    public func parseAnnotation(with item: HasAnnotations) throws -> (any Annotation)? {
        if AnnotationParser.canParse(firstWord: self.firstWord) {
            if let annotation = try AnnotationParser.parse(pInfo: self) {
                item.annotations[annotation.name] = annotation
                try AnnotationProcessor.process(annotation, for: item)
                self.parser.skipLine()
                return annotation
            } else {
                throw Model_ParsingError.invalidAnnotationLine(self)
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
    
    public static func == (lhs: ParsedInfo, rhs: ParsedInfo) -> Bool {
        return (lhs.line == rhs.line) && (lhs.lineNo == rhs.lineNo)
    }
    
    public static func dummy(line: String, identifier: String, with ctx: GenerationContext) -> ParsedInfo {
        let parser = DummyLineParserDuringGeneration(identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        return ParsedInfo(parser: parser, line: line, lineNo: -1, level: 0, firstWord: "")
    }
    
    public static func dummy(line: String, identifier: String, with ctx: LoadContext) -> ParsedInfo {
        let parser = DummyLineParserDuringLoad(identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        return ParsedInfo(parser: parser, line: line, lineNo: -1, level: 0, firstWord: "")
    }
    
    public static func dummy(line: String, identifier: String, with ctx: Context) -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return dummy(line: line, identifier: identifier, with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return dummy(line: line, identifier: identifier, with: genctx)
        } else {
            fatalError("unknown Context passes")
        }
    }
    
    public static func dummyForFrontMatterError(identifier: String, with ctx: Context) -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return dummy(line: "Front-Matter", identifier: identifier, with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return dummy(line: "Front-Matter", identifier: identifier, with: genctx)
        } else {
            fatalError("unknown Context passes")
        }
    }
    
    public static func dummyForMainFile(with ctx: Context) -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return dummy(line: "Main-File", identifier: "Main-File", with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return dummy(line: "Main-File", identifier: "Main-File", with: genctx)
        } else {
            fatalError("unknown Context passes")
        }
    }
    
    public static func dummyForAppState(with ctx: Context) -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return dummy(line: "App-State", identifier: "App-State", with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return dummy(line: "App-State", identifier: "App-State", with: genctx)
        } else {
            fatalError("unknown Context passes")
        }
    }
    
    public init?(parser: LineParser) {
        //the currentLine() returns a trummed string, which removes prefixed space for content;
        //so, another method, that does not trim prefix, is used
        self.line = parser.currentLine_TrimTrailing()
        self.lineNo = parser.curLineNoForDisplay
        
        let (firstWord, secondWord) = line.firstAndsecondWord()

        guard let firstWord = firstWord else { return nil }
        self.firstWord = firstWord
        self.secondWord = secondWord
        
        self.parser = parser
        self.level = parser.curLevelForDisplay
        self.identifier = parser.identifier
    }
    
    public init(parser: LineParser, line: String, lineNo: Int, level: Int, firstWord: String) {
        self.line = line
        self.lineNo = lineNo

        self.firstWord = firstWord
        self.parser = parser
        self.level = level
        self.identifier = parser.identifier
    }
}

