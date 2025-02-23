//
// StringConvertible.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol StringConvertible {
    func toString() -> String
}

extension Int : StringConvertible {
    public func toString() -> String {
        return "\(self)"
    }
    
}

extension String : StringConvertible {
    public func toString() -> String {
        return self
    }
    
}

typealias StringConvertibleBuilder = ResultBuilder<StringConvertible> 
