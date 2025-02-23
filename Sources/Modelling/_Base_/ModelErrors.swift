//
// Model_ParsingError.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public enum Model_ParsingError: ErrorWithMessageAndParsedInfo {
    case objectNotFound(String, ParsedInfo)
    case invalidMapping(String, ParsedInfo)
    case invalidPropertyLine(ParsedInfo)
    case invalidMethodLine(ParsedInfo)
    case invalidDerivedProperty(String, ParsedInfo)
    case invalidContainerMemberLine(ParsedInfo)
    case invalidContainerLine(ParsedInfo)
    case invalidModuleLine(ParsedInfo)
    case invalidSubModuleLine(ParsedInfo)
    case invalidDomainObjectLine(ParsedInfo)
    case invalidDtoObjectLine(ParsedInfo)
    case invalidUIViewLine(ParsedInfo)
    case invalidAnnotationLine(ParsedInfo)
    case invalidAttachedSection(ParsedInfo)
    case invalidApiLine(ParsedInfo)
    case invalidPropertyUsedInApi(String, ParsedInfo)
    case moduleNameEmpty(ParsedInfo)

    public var info: String {
        switch (self) {
        case .objectNotFound(let obj, _) : return "object: \(obj) not found"
        case .invalidPropertyLine(let pInfo) : return "invalid property: \(pInfo.line)"
        case .invalidDerivedProperty(let msg, _) : return "invalid derived property: \(msg)"
        case .invalidMethodLine(let pInfo) : return "invalid method: \(pInfo.line)"

        case .invalidMapping(let mapping, _) : return "invalid mapping: \(mapping)"
        case .invalidAnnotationLine(let pInfo) :
            return "invalid annotation: \(pInfo.line)"
            
        case .invalidContainerLine(let pInfo) : return "invalid container: \(pInfo.line)"
        case .invalidContainerMemberLine(let pInfo) : return "invalid container member: \(pInfo.line)"
        case .invalidModuleLine(let pInfo) : return "invalid module: \(pInfo.line)"
        case .invalidSubModuleLine(let pInfo) : return "invalid sub module: \(pInfo.line)"
        case .invalidAttachedSection(let pInfo) : return "invalid attached section: \(pInfo.line)"
                
        case .invalidDomainObjectLine(let pInfo) : return "invalid domain object: \(pInfo.line)"
        case .invalidDtoObjectLine(let pInfo) : return "invalid dto object: \(pInfo.line)"
        case .invalidUIViewLine(let pInfo) : return "invalid ui view: \(pInfo.line)"

        case .invalidApiLine(let pInfo) : return "invalid api: \(pInfo.line)"
        case .invalidPropertyUsedInApi(let prop, let pInfo) :
            return "invalid property \(prop) used in '\(pInfo.line)'"

        case .moduleNameEmpty(_) : return "module Name Empty"
        }
    }

    public var pInfo: ParsedInfo {
        return switch (self) {
        case .objectNotFound(_, let pInfo) : pInfo
        case .invalidPropertyLine(let pInfo) : pInfo
        case .invalidDerivedProperty(_, let pInfo) : pInfo
        case .invalidMethodLine(let pInfo) : pInfo

        case .invalidMapping(_, let pInfo) : pInfo
        case .invalidAnnotationLine(let pInfo) :pInfo
            
        case .invalidContainerLine(let pInfo) : pInfo
        case .invalidContainerMemberLine(let pInfo) : pInfo
        case .invalidModuleLine(let pInfo) : pInfo
        case .invalidSubModuleLine(let pInfo) : pInfo
        case .invalidAttachedSection(let pInfo) : pInfo
                
        case .invalidDomainObjectLine(let pInfo) : pInfo
        case .invalidDtoObjectLine(let pInfo) : pInfo
        case .invalidUIViewLine(let pInfo) : pInfo

        case .invalidApiLine(let pInfo) : pInfo
        case .invalidPropertyUsedInApi(_, let pInfo) : pInfo

        case .moduleNameEmpty(let pInfo) : pInfo
        }
    }
}
