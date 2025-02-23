//
// Array.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension Array {
    mutating func forEach(by transform: (inout Element) throws -> Void) rethrows {
        self = try map { el in
            var el = el
            try transform(&el)
            return el
        }
     }
}
