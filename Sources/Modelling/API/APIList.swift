//
//  APIList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class APIList : IteratorProtocol, Sequence {
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
    
    public func next() -> API? {
        if currentIndex <= items.count - 1 {
            let compo = items[currentIndex]
            currentIndex += 1
            return compo
        } else {
            currentIndex = 0 //reset index
            return nil
        }
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
    
    public var debugDescription: String {
        return """
        \(self.name)
        \(self.items.count) items
        """
    }
    
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
