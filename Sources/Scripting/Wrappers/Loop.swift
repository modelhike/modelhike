//
// Loop.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ForLoop_Wrap : DynamicMemberLookup {
    public private(set) var item: ForStmt?
    public var FIRST_IN_LOOP = false
    public var LAST_IN_LOOP = false
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        let value: Any = switch propname {
            case "first": FIRST_IN_LOOP
            case "last" : LAST_IN_LOOP
            
           default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
        
        return value
    }
    
    public var debugDescription: String { item?.debugDescription ?? ""}

    public init(_ item: ForStmt) {
        self.item = item
    }
    
    public init() {
        self.item = nil
    }
}

