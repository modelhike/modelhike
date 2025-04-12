//
//  StringConvertible.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
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
