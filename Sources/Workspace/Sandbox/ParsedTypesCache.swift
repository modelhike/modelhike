//
//  ParsedTypesCache.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor ParsedTypesCache : SendableDebugStringConvertible {
    public private(set) var items: [CodeObject] = []
    
    public func getLastPropInRecursive(_ propName: String, inObj objectName: String) async -> Property? {
        if let obj = await self.get(for: objectName) {
            if let prop = await obj.getLastPropInRecursive(propName, appModel: self) {
                return prop
            }
        }
        
        return nil
    }
        
    public func get(for name: String) async -> CodeObject? {
        for item in items {
            let item_givenname = await item.givenname
            let item_name = await item.name
            
            if item_givenname.lowercased() == name.lowercased() ||
                item_name.lowercased() == name.lowercased() {
                return item
            }
        }
        return nil
    }
     
    public func append(_ item: CodeObject) {
        items.append(item)
    }
    
    public func append(_ newItems : [CodeObject]) {
        items.append(contentsOf: newItems)
    }
    
    public var debugDescription: String { get async {
        var str =  """
                    Types \(self.items.count) items:
                    """
        str += .newLine
        
        for item in items {
            let givenname = await item.givenname
            str += givenname + .newLine
            
        }
        
        return str
    }}
    
    public init() {}
}
