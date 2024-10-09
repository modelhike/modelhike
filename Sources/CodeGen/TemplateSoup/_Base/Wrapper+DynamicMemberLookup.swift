//
// DynamicMemberLookup.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol DynamicMemberLookup {
    func dynamicLookup(property propname: String, lineNo: Int) throws -> Any
}

public protocol ObjectWrapper : DynamicMemberLookup, HasAttributes, CustomDebugStringConvertible {
    
}
