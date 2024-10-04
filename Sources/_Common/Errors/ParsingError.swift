//
// ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParsingError: Error {
    case invalidLine(Int, String, String, Error)
    case invalidLineWithInfo_HavingLineno(String, String, Error)
    case invalidLineWithoutErr(Int, String, String)
    case unrecognisedParsingDirective(Int, String, String)
    case invalidParsingDirective(Int, String, String)

    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let identifier, let info,  _) :
            return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)
                """
            case .invalidLineWithInfo_HavingLineno(let identifier, let info,  _) :
                return "🐞🐞 \(identifier) >> \(info)"
            case .invalidLineWithoutErr(let lineNo,let identifier, let info) :
            return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)
                """
            case .unrecognisedParsingDirective(let lineNo, let identifier, let directiveName) :
                return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] Unrecognised Parsing Directive '\(directiveName)'
                """
            case .invalidParsingDirective(let lineNo, let identifier, let line) :
                return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] invalid Parsing Directive '\(line)'
                """
        }
    }

}
