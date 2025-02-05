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
    public let givenKey: String
    public var value: Optional<Any>
    
    public var name : String { givenKey }
    
    public func hash(into hasher: inout Hasher) {
       hasher.combine(key)
     }
    
    public static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        return lhs.key == rhs.key
    }
    
    public init(key: String, givenKey: String, value: Any) {
        self.key = key
        self.givenKey = givenKey
        self.value = value
    }
    
    public init(_ key: String, value: Any) {
        self.key = key
        self.givenKey = key
        self.value = value
    }
}

public class Attributes : ExpressibleByDictionaryLiteral, CustomDebugStringConvertible {
    public typealias Key = String
    public typealias Value = Optional<Any>
    
    private var items: Set<Attribute> = Set()
    
    public var isEmpty: Bool { items.isEmpty }
    
    public func processEach(by process: (Attribute) throws -> Attribute?) throws {
        var itemsToRemove: [Attribute] = []

        for item in items {
            if try process(item) == nil {
                itemsToRemove.append(item)
            }
        }
        
        // Remove the collected elements from the attributes set
        for item in itemsToRemove {
            items.remove(item)
        }
    }
    
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
                items.insert(Attribute(key: keyToFind, givenKey: key, value: newValue as Any))
            }
            
        }
    }
    
    public func getString(_ key: String) -> Optional<String> {
        let keyToFind = key.lowercased()
        if let item = items.first(where: {$0.key == keyToFind}) {
            return item.value as? String
        } else {
            return nil
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
    
    public var debugDescription: String {
        var str =  """
                    Attributes \(self.items.count) items:
                    """
        str += .newLine
        
        for item in items {
            str += item.key + .newLine
            
        }
        
        return str
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
