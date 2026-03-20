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
        let normalizedName = name.lowercased()
        let fallbackNames = normalizedFallbackNames(for: name)

        for item in items {
            let itemNames = [
                await item.givenname.lowercased(),
                await item.name.lowercased(),
            ]

            if itemNames.contains(normalizedName) {
                return item
            }

            for itemName in itemNames where fallbackNames.contains(itemName) {
                return item
            }
        }
        return nil
    }


    private func normalizedFallbackNames(for name: String) -> [String] {
        var normalized: [String] = []
        for candidate in referenceFallbackNames(for: name) {
            normalized.append(candidate.lowercased())
        }
        return normalized
    }

    private func referenceFallbackNames(for name: String) -> [String] {
        if let targets = PropertyKind.parse(name).referenceTargets {
            targets.map(\.targetName).filter(\.isNotEmpty)
        } else {
            []
        }
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
