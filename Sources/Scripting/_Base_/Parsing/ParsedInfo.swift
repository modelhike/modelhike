//
//  ParsingContext.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ParsedInfo : Sendable {
    public private(set) var line: String
    public private(set) var lineNo: Int
    public private(set) var level: Int
    public private(set) var firstWord: String
    public private(set) var secondWord: String? = nil

    public private(set) var identifier: String
    public private(set) var parser: LineParser
    public private(set) var ctx: Context
    
    public func parseAttachedItems(for obj: ArtifactHolder, with section: AttachedSection) async throws -> [Artifact] {
        if let cls = obj as? CodeObject {
            let name = await section.name.lowercased()
            if name == "apis" {
                return try await APISectionParser.parse(for: cls, lineParser: self.parser)
            }
        }
        
        return []
    }
    
    public func tryParseAttachedSections(with item: ArtifactHolderWithAttachedSections) async throws -> Bool {
        if AttachedSectionParser.canParse(firstWord: self.firstWord) {
            if let section = try await AttachedSectionParser.parse(for: item, with: self) {
                await item.attachedSections.set(section.name, value: section)
                return true
            } else {
                throw Model_ParsingError.invalidAttachedSection(self)
            }
        }
        
        return false
    }
    
    public func parseAnnotation(with item: HasAnnotations_Actor) async throws -> (any Annotation)? {
        if AnnotationParser.canParse(firstWord: self.firstWord) {
            if let annotation = try AnnotationParser.parse(pInfo: self) {
                await item.annotations.set(annotation.name, value:  annotation)
                //try AnnotationProcessor.process(annotation, for: item)
                await self.parser.skipLine()
                return annotation
            } else {
                throw Model_ParsingError.invalidAnnotationLine(self)
            }
        }
        
        return nil
    }
    
    public func tryParseAnnotations(with item: HasAnnotations_Actor) async throws -> Bool {
        if let _ = try await parseAnnotation(with: item) {
            return true
        } else {
            return false
        }
    }
    
    public static func == (lhs: ParsedInfo, rhs: ParsedInfo) -> Bool {
        return (lhs.line == rhs.line) && (lhs.lineNo == rhs.lineNo)
    }
    
    public static func dummy(line: String, identifier: String, generationCtx ctx: GenerationContext) async -> ParsedInfo {
        let parser = DummyLineParserDuringGeneration(identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        return await ParsedInfo(parser: parser, line: line, lineNo: -1, level: 0, firstWord: "")
    }
    
    public static func dummy(line: String, identifier: String, loadCtx ctx: LoadContext) async -> ParsedInfo {
        let parser = DummyLineParserDuringLoad(identifier: identifier, isStatementsPrefixedWithKeyword: true, with: ctx)
        return await ParsedInfo(parser: parser, line: line, lineNo: -1, level: 0, firstWord: "")
    }
    
    public static func dummy(line: String, identifier: String, with ctx: Context) async -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return await dummy(line: line, identifier: identifier, loadCtx: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return await dummy(line: line, identifier: identifier, generationCtx: genctx)
        } else {
            fatalError(#function + ": unknown Context passes")
        }
    }
    
    public static func dummyForFrontMatterError(identifier: String, with ctx: Context) async -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return await dummy(line: "Front-Matter", identifier: identifier, with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return await dummy(line: "Front-Matter", identifier: identifier, with: genctx)
        } else {
            fatalError(#function + ": unknown Context passes")
        }
    }
    
    public static func dummyForMainFile(with ctx: Context) async -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return await dummy(line: "Main-File", identifier: "Main-File", with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return await dummy(line: "Main-File", identifier: "Main-File", with: genctx)
        } else {
            fatalError(#function + ": unknown Context passes")
        }
    }
    
    public static func dummyForAppState(with ctx: Context) async -> ParsedInfo {
        if let loadctx = ctx as? LoadContext {
            return await dummy(line: "App-State", identifier: "App-State", with: loadctx)
        } else if let genctx = ctx as? GenerationContext {
            return await dummy(line: "App-State", identifier: "App-State", with: genctx)
        } else {
            fatalError(#function + ": unknown Context passes")
        }
    }
    
    public mutating func firstWord(_ firstWord: String) {
        self.firstWord = firstWord
    }
    
    public mutating func removeLine(after word: String) {
        self.line = line.remainingLine(after: word)
    }
    
    public mutating func setLineInfo(line: String, lineNo: Int) {
        self.line = line
        self.lineNo = lineNo
    }
    
    public init?(parser: LineParser) async {
        //the currentLine() returns a trummed string, which removes prefixed space for content;
        //so, another method, that does not trim prefix, is used
        self.line = await parser.currentLine_TrimTrailing()
        self.lineNo = await parser.curLineNoForDisplay
        
        let (firstWord, secondWord) = line.firstAndsecondWord()

        guard let firstWord = firstWord else { return nil }
        self.firstWord = firstWord
        self.secondWord = secondWord
        
        self.parser = parser
        self.level = await parser.curLevelForDisplay
        self.identifier = await parser.identifier
        
        self.ctx = await parser.ctx
    }
    
    public init(parser: LineParser, line: String, lineNo: Int, level: Int, firstWord: String) async {
        self.line = line
        self.lineNo = lineNo

        self.firstWord = firstWord
        self.parser = parser
        self.level = level
        self.identifier = await parser.identifier
        
        self.ctx = await parser.ctx
    }
}

