//
// Tag.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol HasTags {
    var tags: Tags {get set}
}

public class Tags {
    private var items: Set<Tag> = Set()

    public func processEach(by process: (Tag) throws -> Tag?) throws {
        var itemsToRemove: [Tag] = []
        
        for item in items {
            if try process(item) == nil {
                itemsToRemove.append(item)
            }
        }
        
        // Remove the collected elements from the tag set
        for item in itemsToRemove {
            items.remove(item)
        }
    }
    
    public func has(_ name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let _ = items.first(where: { $0.name == nameToCheck}) {
            return true
        } else {
            return false
        }
    }
    
    public subscript(key: String) -> Optional<Tag> {
        get {
            let keyToFind = key.lowercased()
            return items.first(where: {$0.name == keyToFind})
        }
        set {
            let keyToFind = key.lowercased()
            if let item = items.first(where: {$0.name == keyToFind}) {
                items.update(with: item)
            } else { // new attr
                if let value = newValue {
                    items.insert(value)
                }
            }
        }
    }
    
    @discardableResult
    func append(_ str: String) -> Self {
        self[str] = Tag(str)
        return self
    }
                     
    @discardableResult
    func append(_ str: String, arg: String) -> Self {
        self[str] = Tag(str, arg: arg)
        return self
    }
}

public struct Tag : Hashable {
    public let name: String
    public let givenname: String
    public var args: [String] = []
    
    public var arg : String? { args.first }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name
    }
    
    public static func == (lhs: Tag, rhs: String) -> Bool {
        return lhs.name == rhs.lowercased()
    }
    
    public func `is`(_ tagname: String) -> Bool {
        return name == tagname.lowercased()
    }
    
    public init(_ name: String, arg: String) {
        self.givenname = name.trim()
        self.name = givenname.lowercased()
        self.args = [arg]
    }
    
    public init(_ name: String) {
        self.givenname = name.trim()
        self.name = givenname.lowercased()
    }
}
