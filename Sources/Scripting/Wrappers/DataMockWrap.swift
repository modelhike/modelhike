//
//  Mocking_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor Mocking_Wrap : DynamicMemberLookup {
    public private(set) var item: MockData_Generator
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {

        let value: Sendable = switch propname {
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
