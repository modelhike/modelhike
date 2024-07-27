//
// Attribute.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol HasAttributes {
    var attribs: Attributes {get set}
}

public struct Attribute: Hashable {
    public let key: String
    public var value: Optional<Any>
    
    public func hash(into hasher: inout Hasher) {
       hasher.combine(key)
     }
    
    public static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        return lhs.key == rhs.key
    }
    
    public init(_ key: String, value: Any) {
        self.key = key
        self.value = value
    }
}

public class Attributes : ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Optional<Any>
    
    private var items: Set<Attribute> = Set()
    
    public var isEmpty: Bool { items.isEmpty }
    
    public func has(_ name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let _ = items.first(where: { $0.key == nameToCheck}) {
            return true
        } else {
            return false
        }
    }
    
    public subscript(key: String) -> Optional<Any> {
        get {
            let keyToFind = key.lowercased()
            return items.first(where: {$0.key == keyToFind})?.value as Any
        }
        set {
            let keyToFind = key.lowercased()
            if var item = items.first(where: {$0.key == keyToFind}) {
                item.value = newValue
                items.update(with: item)
            } else { // new attr
                items.insert(Attribute(keyToFind, value: newValue as Any))
            }
            
        }
    }
    
    public var attributesList : [Attribute] {
        return Array(items)
    }
    
    @discardableResult
    func removeValue(forKey name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let item = items.first(where: { $0.key == nameToCheck}) {
            if let index = self.items.firstIndex(of: item) {
                self.items.remove(at: index)
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public init() { }
    
    required public init(dictionaryLiteral elements: (String, Optional<Any>)...) {
        for (key,value) in elements {
            items.insert(Attribute(key, value: value as Any))
        }
    }
}

public enum AttributeNamePresets : String {
    case validValues = "oneof" //oneOf
}
