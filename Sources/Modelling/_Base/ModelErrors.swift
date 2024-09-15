//
// Model_ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Model_ParsingError: Error {
    case objectNotFound(String)
    case invalidMapping(String)
    case invalidPropertyLine(String)
    case invalidContainerMemberLine(String)
    case invalidAnnotation(String)
    case moduleNameEmpty

    public var info: String {
        switch (self) {
            case .objectNotFound(let obj) : return "object: \(obj) not found"
            case .invalidPropertyLine(let prop) : return "property: \(prop) invalid"
            case .invalidMapping(let mapping) : return "mapping: \(mapping) is invalid"
            case .invalidAnnotation(let annotation) : return "annotation: \(annotation) is invalid"
            
            case .invalidContainerMemberLine(let line) : return "container member: \(line) invalid"
            case .moduleNameEmpty : return "moduleNameEmpty"

        }
    }

}
