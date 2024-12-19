//
// MappingAnnotation.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct MappingAnnotation: Annotation {
    
    public let name: String
    public let parsedContextInfo: ParsedContextInfo
    
    public private(set) var mappings: [String: String] = [:]
    
    public func hash(into hasher: inout Hasher) {
       hasher.combine(name)
     }
    
//    public static func == (lhs: MappingAnnotation, rhs: any Annotation) -> Bool {
//        return lhs.name == rhs.name
//    }
//    
//    public static func == (lhs: any Annotation, rhs: MappingAnnotation) -> Bool {
//        return lhs.name == rhs.name
//    }
    
    public static func == (lhs: MappingAnnotation, rhs: MappingAnnotation) -> Bool {
        return lhs.name == rhs.name
    }
    
    public init(_ name: String, line: Substring, with pctx: ParsedInfo) throws {
        self.name = name.trim()
        self.parsedContextInfo = ParsedContextInfo(with: pctx)
        
        let components = line.split(separator: ";", omittingEmptySubsequences: true)
        for component in components {
            let split = component.split(separator: "->")
            if split.count == 2 {
                let key = split[0].trim()
                let value = split[1].trim()
                self.mappings[key] = value
                
            } else {
                throw Model_ParsingError.invalidMapping(String(component))
            }
        }
    }
}
