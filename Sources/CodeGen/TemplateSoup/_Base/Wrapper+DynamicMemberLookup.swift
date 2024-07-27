//
// DynamicMemberLookup.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol DynamicMemberLookup {
  subscript(member: String) -> Any { get }
}

public protocol ObjectWrapper : DynamicMemberLookup, HasAttributes {
    
}
