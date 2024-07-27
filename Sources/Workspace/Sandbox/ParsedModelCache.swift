//
// ParsedModelCache.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ParsedModelCache {
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
        return items.first(where: { $0.givename == name || $0.name == name })
    }
     
    public func append(_ item: CodeObject) {
        items.append(item)
    }
    
    public func append(_ newItems : [CodeObject]) {
        items.append(contentsOf: newItems)
    }
    
    public init() {}
}
