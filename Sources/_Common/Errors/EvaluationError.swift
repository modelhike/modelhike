//
// EvaluationError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum EvaluationError: Error {
    case invalidLine(Int, String, String, Error)
    case invalidInput(String)
    case invalidAppState(String)
    case workingDirectoryNotSet(Int, String)
    
    public var info: String {
        switch (self) {
            case .invalidLine(let lineNo, let info, let identifier,  _) :
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] \(info)"
            case .invalidInput(let msg): return msg
            case .invalidAppState(let msg): return msg
            case .workingDirectoryNotSet(let lineNo, let identifier) : 
                return "🐞🐞 \(identifier) >> [line no : \(lineNo)] Working Directory not set!!!"
        }
    }

}
