//
// Dictionary.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension Dictionary {
    mutating func merge(contentsOf dictFrom: Dictionary) {
        
        dictFrom.forEach { (key, value) in
            self[key] = value
        }
    }
}

public extension StringDictionary {
    func has(_ name: String) -> Bool {
        if let _ = self[name] {
            return true
        } else {
            return false
        }
    }
}
