//
// CodeGenerationEvents.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias BeforeRenderFileHandler = (_ fileName: String, _ pInfo: ParsedInfo) throws -> Bool
public typealias StartParseObjectHandler = (_ objectName: String, _ pInfo: ParsedInfo) throws -> Void

public class CodeGenerationEvents {
    public var onBeforeRenderFile : BeforeRenderFileHandler?
    
    public var onStartParseObject : StartParseObjectHandler?
    
    public func canRender(filename: String, with pInfo: ParsedInfo) throws -> Bool{
        if let onBeforeRenderFile = onBeforeRenderFile {
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
