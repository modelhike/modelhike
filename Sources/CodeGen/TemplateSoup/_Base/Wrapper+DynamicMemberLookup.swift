//
// DynamicMemberLookup.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol DynamicMemberLookup {
    func dynamicLookup(property propname: String, pInfo: ParsedInfo) throws -> Any
}

public protocol ObjectWrapper : DynamicMemberLookup, HasAttributes, CustomDebugStringConvertible {
    
}
