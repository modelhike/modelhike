//
//  DynamicMemberLookup.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol DynamicMemberLookup: Any {
    func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any
    func hasSettable(property propname: String) -> Bool
    //func setValueOf(property propname: String, value: Any, with pInfo: ParsedInfo) throws -> Bool
}

public extension DynamicMemberLookup {
    func hasSettable(property propname: String) -> Bool {
        return false
    }
    
    mutating func setValueOf(property propname: String, value: Any?, with pInfo: ParsedInfo) throws {
        throw ParsingError.featureNotImplementedYet(pInfo)
        //RuntimeReflection.setValue(value, forProperty: propname, in: &self)
    }
}

public protocol ObjectWrapper : DynamicMemberLookup, HasAttributes, CustomDebugStringConvertible {
    
}
