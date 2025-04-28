//
//  Array.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public extension Array {
    mutating func forEach(by transform: @escaping @Sendable (inout Element) throws -> Void) rethrows {
        for i in indices {
            try transform(&self[i])
        }
//        self = try map { el in
//            var el = el
//            try transform(&el)
//            return el
//        }
     }
    
    mutating func forEach(by transform: @escaping @Sendable (inout Element) async throws -> Void) async rethrows {
        for i in indices {
            try await transform(&self[i])
        }
     }
}
