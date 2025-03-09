//
//  Loop.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ForLoop_Wrap : DynamicMemberLookup, CustomDebugStringConvertible {
    public private(set) var item: ForStmt
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
    
    public var debugDescription: String {
        let str =  """
        FOR stmt (level: \(item.pInfo.level))
        |- forVar: \(item.ForVar)
        |- inVar: \(item.InArrayVar)
        
        """
                
        return str
    }

    public init(_ item: ForStmt) {
        self.item = item
    }
}

