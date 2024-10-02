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
    case invalidDerivedPropertyLine(String)
    case invalidContainerMemberLine(String)
    case invalidContainerLine(String)
    case invalidModuleLine(String)
    case invalidSubModuleLine(String)
    case invalidAnnotation(String)
    case invalidAttachedSection(String)
    case moduleNameEmpty

    public var info: String {
        switch (self) {
            case .objectNotFound(let obj) : return "object: \(obj) not found"
            case .invalidPropertyLine(let prop) : return "invalid property: \(prop)"
            case .invalidDerivedPropertyLine(let prop) : return "invalid derived property: \(prop)"
            case .invalidMapping(let mapping) : return "invalid mapping: \(mapping)"
            case .invalidAnnotation(let annotation) : return "invalid annotation: \(annotation)"
            
            case .invalidContainerLine(let line) : return "invalid container: \(line)"
            case .invalidContainerMemberLine(let line) : return "invalid container member: \(line)"
            case .invalidModuleLine(let line) : return "invalid module: \(line)"
            case .invalidSubModuleLine(let line) : return "invalid sub module: \(line)"
            
            case .invalidAttachedSection(let line) : return "invalid attached section: \(line)"
            case .moduleNameEmpty : return "module Name Empty"

        }
    }

}
