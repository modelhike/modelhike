//
//  APIList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor APIList : _CollectionAsyncSequence, SendableDebugStringConvertible {
    public var name: String = ""
    public private(set) var items : [API] = []
    private var currentIndex = 0
    
    public func forEach(by transform: (inout API) throws -> Void) rethrows {
        _ = try items.map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
    
    public func snapshot() async -> [any Sendable] {
        items
    }
    
    public func append(_ item: API) {
        items.append(item)
    }
    
    public func append(contentsOf newItems: [API]) {
        self.items.append(contentsOf: newItems)
    }
    
    public func removeAll() {
        items.removeAll()
    }
    
    public var count: Int { items.count }
    
    public var debugDescription: String { get async {
        return """
        \(self.name)
        \(self.items.count) items
        """
    }}
    
    public init(name: String = "", _ items: API...) {
        self.name = name
        self.items = items
    }
    
    public init(name: String = "", _ items: [API]) {
        self.name = name
        self.items = items
    }
    
    public init() {}
}
