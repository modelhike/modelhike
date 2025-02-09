//
// ParserDirectives.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParserDirective: ErrorWithMessage {
    static var includeIf = "include-if"
    static var includeFor = "include-for"
    static var outputFilename = "file-name"

    case excludeFile(String)
    
    
    public var info: String {
        switch (self) {
            case .excludeFile(let msg): return msg
                
        }
    }
    
}
