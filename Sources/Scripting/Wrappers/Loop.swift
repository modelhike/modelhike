//
//  Loop.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ForLoop_Wrap : DynamicMemberLookup, SendableDebugStringConvertible {
    public private(set) var item: ForStmt
    public private(set) var FIRST_IN_LOOP = false
    public private(set) var LAST_IN_LOOP = false
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable? {
        let value: Sendable = switch propname {
            case "first": FIRST_IN_LOOP
            case "last" : LAST_IN_LOOP
            
           default:
            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
        }
        
        return value
    }
    
    public func FIRST_IN_LOOP(_ value: Bool) {
        self.FIRST_IN_LOOP = value
    }
    
    public func LAST_IN_LOOP(_ value: Bool) {
        self.LAST_IN_LOOP = value
    }
    
    public var debugDescription: String { get async {
        let str =  """
        FOR stmt (level: \(item.pInfo.level))
        |- forVar: \(item.ForVar)
        |- inVar: \(item.InArrayVar)
        
        """
        
        return str
    }}

    public init(_ item: ForStmt) {
        self.item = item
    }
}

