//
// EvaluationError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum EvaluationError: Error {
    case invalidLine(Int, String, String, Error)
    case invalidLineWithInfo_HavingLineno(String, String, Error)
    case invalidInput(String)
    case invalidAppState(String)
    case workingDirectoryNotSet(Int, String)
    case templateDoesNotExist(Int, String, String)
    case readingError(Int, String, String)

    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let identifier, let info,  _) :
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)"
            case .invalidLineWithInfo_HavingLineno(let identifier, let info,  _) :
                return "🐞🐞 \(identifier) >> \(info)"
            case .invalidInput(let msg): return msg
            case .invalidAppState(let msg): return msg
            case .workingDirectoryNotSet(let lineNo, let identifier) : 
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] Working info not set!!!"
            case .templateDoesNotExist(let lineNo, let identifier, let info) :
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)"
            case .readingError(let lineNo, let identifier, let info) :
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)"
        }
    }

}
