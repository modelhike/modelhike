//
//  Attribute.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol HasAttributes {
    var attribs: Attributes { get }
}

public protocol HasAsyncAttributes {
    var attribs: Attributes { get async }
}

public protocol HasAttributes_Actor: Actor {
    var attribs: Attributes { get }
}

//public typealias Attribute = SendableAttribute<AnySendable>

public struct Attribute: Hashable, Sendable {
    public let key: String
    public let givenKey: String
    public fileprivate(set) var value: Optional<Sendable>

    public var name: String { givenKey }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    public static func == (lhs: Attribute, rhs: Attribute) -> Bool {
        return lhs.key == rhs.key
    }

    public init(key: String, givenKey: String, value: Optional<Sendable>) {
        self.key = key
        self.givenKey = givenKey
        self.value = value
    }

    public init(_ key: String, value: Optional<Sendable>) {
        self.key = key
        self.givenKey = key
        self.value = value
    }
}

public actor Attributes: SendableDebugStringConvertible, Sendable {
    public typealias Key = String
    public typealias Value = Any?

    private var items: Set<Attribute> = Set()

    public var isEmpty: Bool { items.isEmpty }

    public func processEach(by process: (Attribute) async throws -> Attribute?) async throws {
        var itemsToRemove: [Attribute] = []

        for item in items {
            if try await process(item) == nil {
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
        if items.first(where: { $0.key == nameToCheck }) != nil {
            return true
        } else {
            return false
        }
    }

    public func set(_ key: String, value newValue: Sendable?) {
        let keyToFind = key.lowercased()
        if var item = items.first(where: { $0.key == keyToFind }) {
            item.value = newValue
            items.update(with: item)
        } else {  // new attr
            items.insert(Attribute(key: keyToFind, givenKey: key, value: newValue))
        }
    }

    public subscript(key: String) -> Sendable? {
        let keyToFind = key.lowercased()
        return items.first(where: { $0.key == keyToFind })?.value
    }

    public func getString(_ key: String) -> String? {
        let keyToFind = key.lowercased()
        if let item = items.first(where: { $0.key == keyToFind }) {
            return item.value as? String
        } else {
            return nil
        }
    }

    public var attributesList: [Attribute] {
        return Array(items)
    }

    @discardableResult
    func removeValue(forKey name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if let item = items.first(where: { $0.key == nameToCheck }) {
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

    public nonisolated var debugDescription: String {
        get async {
            var str = """
                    Attributes \(await items.count) items:
                    """
            str += .newLine
            
            for item in await items {
                str += item.key + .newLine
                
            }
            
            return str
        }
    }

    public init() {}
}

public enum AttributeNamePresets: String, Sendable {
    case validValues = "oneof"  //oneOf
}
