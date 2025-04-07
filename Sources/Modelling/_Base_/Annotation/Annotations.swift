//
//  Annotations.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol HasAnnotations {
    var annotations: Annotations { get }
}

public protocol HasAnnotations_Actor: Actor {
    var annotations: Annotations { get async }
}

public protocol Annotation: Hashable, Sendable {
    var name: String { get }
    var pInfo: ParsedInfo { get }
}

public actor Annotations {

    private var items: [String: any Annotation] = [:]

    public var isEmpty: Bool { items.isEmpty }

    func has(_ name: String) -> Bool {
        let nameToCheck = name.lowercased()
        if items[nameToCheck] != nil {
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

    public func append(contentsOf annotations: Annotations) async  {
        let items = await annotations.items
        for (key, value) in items {
            self[key] = value
        }
    }

    public var annotationsList: [any Annotation] {
        var arr: [any Annotation] = []

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

    public init() {}

}
