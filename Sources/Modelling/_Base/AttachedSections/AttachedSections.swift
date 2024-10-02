//
// AttachedSection.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol HasAttachedSections : HasAttachedItems {
    var attachedSections : AttachedSections {get set}
}

public protocol HasAttachedItems : AnyObject {
    var attached : [Artifact] {get set}
    @discardableResult func appendAttached(_ item: Artifact) -> Self
}

public class AttachedSections : ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
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
    
    public subscript(key: String) -> AttachedSection? {
        get {
            let keyToFind = key.lowercased()
            return items[keyToFind]
        }
        set {
            let keyToFind = key.lowercased()
            items[keyToFind] = newValue
        }
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
    
    required public init(arrayLiteral elements: AttachedSection...) {
        for item in elements {
            items[item.name] = item
        }
    }
    
    required public init(dictionaryLiteral elements: (String, AttachedSection)...) {
        for (key,value) in elements {
            items[key] = value
        }
    }
}
