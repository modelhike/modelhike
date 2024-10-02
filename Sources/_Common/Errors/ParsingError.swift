//
// ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParsingError: Error {
    case invalidLine(Int, String, String, Error)
    case invalidLineWithoutErr(Int, String, String)

    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let info, let identifier, _) :
            return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)
                """
            
            case .invalidLineWithoutErr(let lineNo, let info, let identifier) :
            return """
                🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)
                """
        }
    }

}
