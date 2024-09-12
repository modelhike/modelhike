//
// ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParsingError: Error {
    case invalidLine(Int, String, Error)
    case invalidLineWithoutErr(Int, String)

    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let info, _) :
            return """
                [line no : \(lineNo)] \(info)
                """
            
            case .invalidLineWithoutErr(let lineNo, let info) :
            return """
                [line no : \(lineNo)] \(info)
                """
        }
    }

}
