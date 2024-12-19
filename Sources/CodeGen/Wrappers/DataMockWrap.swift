//
// Mocking_Wrap.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class Mocking_Wrap : DynamicMemberLookup {
    public private(set) var item: MockData_Generator
    
    public func dynamicLookup(property propname: String, pInfo: ParsedInfo) throws -> Any {

        let value: Any = switch propname {
            case "object-id": item.randomObjectId_MongoDb()
            default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(pInfo.lineNo, propname)
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
