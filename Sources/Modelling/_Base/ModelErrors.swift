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
    case invalidMethodLine(String)
    case invalidDerivedPropertyLine(String)
    case invalidContainerMemberLine(String)
    case invalidContainerLine(String)
    case invalidModuleLine(String)
    case invalidSubModuleLine(String)
    case invalidDomainObjectLine(String)
    case invalidDtoObjectLine(String)
    case invalidUIViewLine(String)
    case invalidAnnotation(Int, String)
    case invalidAttachedSection(String)
    case invalidApiLine(String)
    case invalidPropertyUsedInApi(String, String)
    case moduleNameEmpty

    public var info: String {
        switch (self) {
            case .objectNotFound(let obj) : return "object: \(obj) not found"
            case .invalidPropertyLine(let prop) : return "invalid property: \(prop)"
            case .invalidDerivedPropertyLine(let prop) : return "invalid derived property: \(prop)"
            case .invalidMethodLine(let method) : return "invalid method: \(method)"

            case .invalidMapping(let mapping) : return "invalid mapping: \(mapping)"
            case .invalidAnnotation(let lineNo, let annotation) :
                return "[line no : \(lineNo)] invalid annotation: \(annotation)"
            
            case .invalidContainerLine(let line) : return "invalid container: \(line)"
            case .invalidContainerMemberLine(let line) : return "invalid container member: \(line)"
            case .invalidModuleLine(let line) : return "invalid module: \(line)"
            case .invalidSubModuleLine(let line) : return "invalid sub module: \(line)"
            case .invalidAttachedSection(let line) : return "invalid attached section: \(line)"
                
            case .invalidDomainObjectLine(let line) : return "invalid domain object: \(line)"
            case .invalidDtoObjectLine(let line) : return "invalid dto object: \(line)"
            case .invalidUIViewLine(let line) : return "invalid ui view: \(line)"

            case .invalidApiLine(let line) : return "invalid api: \(line)"
            case .invalidPropertyUsedInApi(let prop, let line) :
                return "invalid property \(prop) used in '\(line)'"

            case .moduleNameEmpty : return "module Name Empty"

        }
    }

}
