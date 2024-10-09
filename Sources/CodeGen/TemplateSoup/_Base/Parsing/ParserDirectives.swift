//
// ParserDirectives.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParserDirectives: Error {
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
