//
// Mocking_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct Mocking_Wrap : DynamicMemberLookup {
    public private(set) var item: MockData_Generator
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {

        let value: Any = switch propname {
            case "object-id": item.randomObjectId_MongoDb()
            default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
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
