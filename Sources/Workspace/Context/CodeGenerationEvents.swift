//
// CodeGenerationEvents.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias BeforeRenderFileHandler = (_ fileName: String, _ ctx: Context) throws -> Bool
public typealias StartParseObjectHandler = (_ objectName: String, _ parser: LineParser, _ ctx: Context) throws -> Void

public class CodeGenerationEvents {
    let context: Context
    
    public var onBeforeRenderFile : BeforeRenderFileHandler?
    
    public var onStartParseObject : StartParseObjectHandler?
    
    public func canRender(filename: String) throws -> Bool{
        if let onBeforeRenderFile = onBeforeRenderFile {
           return try onBeforeRenderFile(filename, context)  //if handler returns false, dont render file
        } else {
            return true
        }
    }
    
    public func onParse(objectName: String, parser: LineParser) throws {
        if let onStartParse = onStartParseObject {
            try onStartParse(objectName, parser, context)  //if handler returns false, dont render file
        }
    }
    
    public init(with ctx: Context) {
        self.context = ctx
    }
}
