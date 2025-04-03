//
//  CodeGenerationEvents.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public typealias BeforeRenderFileHandler = @Sendable (_ fileName: String, _ pInfo: ParsedInfo) throws -> Bool
public typealias BeforeRenderTemplateFileHandler = (_ fileName: String, _ templateName: String, _ pInfo: ParsedInfo) throws -> Bool
public typealias StartParseObjectHandler = @Sendable (_ objectName: String, _ pInfo: ParsedInfo) throws ->
    Void
public typealias BeforeParseTemplateHandler = @Sendable (_ templateName: String, _ ctx: GenerationContext)
    throws -> Void
public typealias BeforeExecuteTemplateHandler = @Sendable (_ templateName: String, _ ctx: GenerationContext)
    throws -> Void
public typealias BeforeParseScriptFileHandler = @Sendable (_ templateName: String, _ ctx: GenerationContext)
    throws -> Void
public typealias BeforeExecuteScriptFileHandler = @Sendable (_ templateName: String, _ ctx: GenerationContext)
    throws -> Void

public actor CodeGenerationEvents: Sendable {
    public var onBeforeRenderFile: BeforeRenderFileHandler?
    public var onBeforeRenderTemplateFile: BeforeRenderTemplateFileHandler?

    public var onBeforeParseTemplate: BeforeParseTemplateHandler?
    public var onBeforeExecuteTemplate: BeforeExecuteTemplateHandler?
    public var onBeforeParseScriptFile: BeforeParseScriptFileHandler?
    public var onBeforeExecuteScriptFile: BeforeExecuteScriptFileHandler?

    public var onStartParseObject: StartParseObjectHandler?

    public func canRender(filename: String, templatename: String, with pInfo: ParsedInfo) throws -> Bool {
        if let onBeforeRenderTemplateFile {
            return try onBeforeRenderTemplateFile(filename, templatename, pInfo)  //if handler returns false, dont render file
        } else {
            return true
        }
    }

    public func canRender(filename: String, with pInfo: ParsedInfo) throws -> Bool {
        if let onBeforeRenderFile {
            return try onBeforeRenderFile(filename, pInfo)  //if handler returns false, dont render file
        } else {
            return true
        }
    }
    
    public func onParse(objectName: String, with pInfo: ParsedInfo) throws {
        if let onStartParse = onStartParseObject {
            try onStartParse(objectName, pInfo)  //if handler returns false, dont render file
        }
    }

    public init() {
    }
}
