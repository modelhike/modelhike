//
// ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum ParsingError: Error {
    case invalidLine(Int, String, Error)

    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let info, _) :
            return """
                [line no : \(lineNo)] \(info)
                """
        }
    }

}
