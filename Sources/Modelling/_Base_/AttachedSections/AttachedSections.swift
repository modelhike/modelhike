//
//  AttachedSection.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol HasAttachedSections : HasAttachedItems {
    var attachedSections : AttachedSections {get set}
}

public protocol HasAttachedItems : AnyObject, Actor {
    var attached : [Artifact] {get set}
    @discardableResult func appendAttached(_ item: Artifact) -> Self
}

public actor AttachedSections {
    public typealias Key = String
    public typealias Value = AttachedSection
    
    private var items: [String: AttachedSection] = [:]
    
    public var isEmpty: Bool { items.isEmpty }
    
    func has(_ name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let _ = items[nameToCheck] {
            return true
        } else {
            return false
        }
    }
    
    public func get(_ key: String) -> AttachedSection? {
        let keyToFind = key.lowercased()
        return items[keyToFind]
    }
    
    public func set(_ key: String, value newValue: AttachedSection)  {
        let keyToFind = key.lowercased()
        items[keyToFind] = newValue
    }
    
    public var annotationsList : [AttachedSection] {
        var arr:[AttachedSection] = []
        
        for value in items.values {
            arr.append(value)
        }
        return arr
    }
    
    @discardableResult
    func removeValue(forKey name: String) -> Bool {
        let item = items.removeValue(forKey: name)
        return item != nil
    }
    
    public init() { }
    
    public init(_  elements: AttachedSection...) async {
        for item in elements {
            let itemName = await item.name
            items[itemName] = item
        }
    }
    
    
//     public init(_ elements: (String, AttachedSection)...) {
//        for (key,value) in elements {
//            items[key] = value
//        }
//    }
//    
//    
}
