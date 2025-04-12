//
//  ParsedTypesCache.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ParsedTypesCache : CustomDebugStringConvertible {
    public private(set) var items: [CodeObject] = []
    
    public func getLastPropInRecursive(_ propName: String, inObj objectName: String) -> Property? {
        if let obj = self.get(for: objectName) {
            if let prop = obj.getLastPropInRecursive(propName, appModel: self) {
                return prop
            }
        }
        
        return nil
    }
        
    public func get(for name: String) -> CodeObject? {
        return items.first(where: { $0.givenname.lowercased() == name.lowercased()
            || $0.name.lowercased() == name.lowercased() })
    }
     
    public func append(_ item: CodeObject) {
        items.append(item)
    }
    
    public func append(_ newItems : [CodeObject]) {
        items.append(contentsOf: newItems)
    }
    
    public var debugDescription: String {
        var str =  """
                    Types \(self.items.count) items:
                    """
        str += .newLine
        
        for item in items {
            str += item.givenname + .newLine
            
        }
        
        return str
    }
    
    public init() {}
}
