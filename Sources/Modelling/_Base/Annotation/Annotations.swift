//
// Annotations.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol HasAnnotations {
    var annotations: Annotations {get set}
}

public protocol Annotation : Hashable {
    var name: String {get}
    var parsedContextInfo: ParsedContextInfo {get}
}

public class Annotations : ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = any Annotation
    
    private var items: [String: any Annotation] = [:]
    
    public var isEmpty: Bool { items.isEmpty }
    
    func has(_ name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let _ = items[nameToCheck] {
            return true
        } else {
            return false
        }
    }
    
    public subscript(key: String) -> (any Annotation)? {
        get {
            let keyToFind = key.lowercased()
            return items[keyToFind]
        }
        set {
            let keyToFind = key.lowercased()
            items[keyToFind] = newValue
        }
    }
    
    public func append(_ item: any Annotation) {
        let keyToFind = item.name.lowercased()
        items[keyToFind] = item
    }
    
    public func append(contentsOf annotations: Annotations) {
        for (key, value) in annotations.items {
            self[key] = value
        }
    }

    
    public var annotationsList : [any Annotation] {
        var arr:[any Annotation] = []
        
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
    
    required public init(arrayLiteral elements: any Annotation...) {
        for item in elements {
            items[item.name] = item
        }
    }
    
    required public init(dictionaryLiteral elements: (String, any Annotation)...) {
        for (key,value) in elements {
            items[key] = value
        }
    }
}
