//
// EvaluationError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum EvaluationError: Error {
    case invalidLine(Int, String, Error)
    case invalidInput(String)
    case invalidAppState(String)
    case workingDirectoryNotSet(Int)
    
    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let info, _) :
            return """
                [line no : \(lineNo)] \(info)
                """
            case .invalidInput(let msg): return msg
            case .invalidAppState(let msg): return msg
            case .workingDirectoryNotSet(let lineNo) : return "[line no : \(lineNo)] Working Directory not set!!!"
        }
    }

}
