//
//  Dictionary.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

extension Dictionary {
    public mutating func merge(contentsOf dictFrom: Dictionary) {

        dictFrom.forEach { (key, value) in
            self[key] = value
        }
    }
}

extension StringDictionary {
    public func has(_ name: String) -> Bool {
        if self[name] != nil {
            return true
        } else {
            return false
        }
    }
}
