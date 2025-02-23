//
// TemplateStmtContainerList.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class SoupyScriptStmtContainerList : IteratorProtocol, Sequence, CustomDebugStringConvertible {
    public let name: String
    var items : [any SoupyScriptStmtContainer] = []
    private var currentIndex = 0
    
    public func forEach(by transform: (inout any SoupyScriptStmtContainer) throws -> Void) rethrows {
        _ = try items.map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
    
    public func next() -> (any SoupyScriptStmtContainer)? {
        if currentIndex <= items.count - 1 {
            let compo = items[currentIndex]
            currentIndex += 1
            return compo
        } else {
            currentIndex = 0 //reset index
            return nil
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
        currentIndex = 0
    }
    
    public var count: Int { items.count }
    
    public func execute(with ctx: Context) throws -> String? {
        var str: String = ""
        
        for item in items {
            if let genericContainer = item as? GenericStmtsContainer {
                if let result = try genericContainer.execute(with: ctx) {
                    str += result
                }
            }
        }
        
        return str.isNotEmpty ? str : nil
    }
    
    public var debugDescription: String {
        var str =  "container list: \(self.name) - \(self.items.count) containers" + "\n"
        
        for item in items {
            str += ( item.debugDescription + "\n" )
        }
        
        return str
    }
    
    public init(name: String, _ items: any SoupyScriptStmtContainer...) {
        self.name = name
        self.items = items
    }
    
    public init(name: String, _ items: [any SoupyScriptStmtContainer]) {
        self.name = name
        self.items = items
    }
    
    public init(name: String) {
        self.name = name
    }
    
    public init() {
        self.name = "string"
    }
}
