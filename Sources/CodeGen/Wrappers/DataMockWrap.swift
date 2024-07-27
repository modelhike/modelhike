//
// Mocking_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class Mocking_Wrap : DynamicMemberLookup {
    public private(set) var item: MockData_Generator
    
    public subscript(member: String) -> Any {
        
        let value: Any = switch member {
            case "object-id": item.randomObjectId_MongoDb()
            default: ""
        }

        return value
    }
    
    public init(_ item: MockData_Generator) {
        self.item = item
    }
    
    public init() {
        self.item = MockData_Generator()
    }
}
