//
// ValuesAnnotation.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ValuesAnnotation: Annotation {
    
    public let name: String
    public let pInfo: ParsedInfo

    public private(set) var values: [String] = []
    
    public func hash(into hasher: inout Hasher) {
       hasher.combine(name)
     }
    
    public static func == (lhs: ValuesAnnotation, rhs: ValuesAnnotation) -> Bool {
        return lhs.name == rhs.name
    }
    
    public init(_ name: String, line: Substring, pInfo: ParsedInfo) throws {
        self.name = name.trim()
        self.pInfo = pInfo

        let components = line.split(separator: ",", omittingEmptySubsequences: true)
        for component in components {
            values.append(String(component.trim()))
        }
    }
}
