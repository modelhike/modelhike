//
//  SoupyScriptStmtContainerList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor SoupyScriptStmtContainerList : _CollectionAsyncSequence, SendableDebugStringConvertible {
    public let name: String
    var items : [any SoupyScriptStmtContainer] = []
    
    public func forEach(by transform: (inout any SoupyScriptStmtContainer) throws -> Void) rethrows {
        _ = try items.map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
    
    public func append(_ item: any SoupyScriptStmtContainer) {
        items.append(item)
    }
    
    public func append(contentsOf newItems: [any SoupyScriptStmtContainer]) {
        self.items.append(contentsOf: newItems)
    }
    
    public func removeAll() {
        items.removeAll()
    }
    
    public func snapshot() async -> [any SoupyScriptStmtContainer] {
        return items
    }
    
    public var count: Int { items.count }
    
    public func execute(with ctx: Context) async throws -> String? {
        var str: String = ""
        
        for item in items {
            if let genericContainer = item as? GenericStmtsContainer {
                if let result = try await genericContainer.execute(with: ctx) {
                    str += result
                }
            }
        }
        
        return str.isNotEmpty ? str : nil
    }
    
    public var debugDescription: String { get async {
        let count = self.items.count
        var str =  "container list: \(self.name) - \(count) containers" + "\n"
        
        for item in items {
            let desp = await item.debugDescription
            str += ( desp + "\n" )
        }
        
        return str
    }}
    
    public init(name: String, _ items: [any SoupyScriptStmtContainer]) {
        self.name = name
        self.items = items
    }
    
    public init(name: String, _ item: any SoupyScriptStmtContainer) {
        self.name = name
        self.items = [item]
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public init() {
        self.name = "string"
    }
}
