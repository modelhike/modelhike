//
//  ParserDirectives.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum ParserDirective: ErrorWithMessage {
    static let includeIf = "include-if"
    static let includeFor = "include-for"
    static let outputFilename = "file-name"

    case excludeFile(String)
    case stopRenderingCurrentFile(String, ParsedInfo)
    case throwErrorFromCurrentFile(String /*filename*/, String /*err msg*/, ParsedInfo)
    
    public var info: String {
        switch (self) {
            case .excludeFile(let file): return file
            case .stopRenderingCurrentFile(let file, _): return file
            case .throwErrorFromCurrentFile(_, let msg, _):
                return "Template Render Error: {\(msg)}"
        }
    }
    
}
