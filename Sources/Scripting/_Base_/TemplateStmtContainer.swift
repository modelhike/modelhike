//
//  SoupyScriptStmtContainer.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol SoupyScriptStmtContainer : _CollectionAsyncSequence, SendableDebugStringConvertible, Actor {
    func append(_ item: TemplateItem)
}

public actor GenericStmtsContainer : SoupyScriptStmtContainer {
    private let kind: TemplateStmtContainerKind
    public var name: String?
    
    var items : [TemplateItem] = []
    public var isEmpty: Bool { items.count == 0 }
    var count: Int { items.count }
    private var currentIndex = 0

    public func append(_ item: TemplateItem) {
        items.append(item)
    }
    
    public func removeAll() {
        items.removeAll()
        currentIndex = 0
    }
    
    public func execute(with ctx: Context) throws -> String? {
        var str: String = ""
        
        for item in items {
            if let result = try item.execute(with: ctx) {
                str += result
            }
        }
        
        return str.isNotEmpty ? str : nil
    }
    
    // Capture a snapshot of items (for safe async access)
    public func snapshot() -> [Sendable] {
        return items
    }
    
    public var debugDescription: String {
        var str =  ""
        if let name = self.name {
            str = "container: \(name) - \(self.items.count) items" + "\n"
        } else {
            str = "container: \(self.items.count) items" + "\n"
        }
        
        str += debugStringForChildren() 
        
        return str
    }
    
    internal func debugStringForChildren() -> String {
        var str = ""
        
        for item in items {
            if let debug = item as? CustomDebugStringConvertible {
                str += ( debug.debugDescription + "\n" )
            }
        }
        
        return str
    }
    
    public init(_ kind: TemplateStmtContainerKind, name: String? = nil) {
        self.kind = kind
        self.name = name
    }
    
    public init() {
        self.kind = .global
    }
    
    public init(_ kind: TemplateStmtContainerKind, name: Substring? = nil) {
        self.kind = kind
        
        if let name = name {
            self.name = String(name)
        }
    }
}

public enum TemplateStmtContainerKind: Sendable {
    case global, partOfMultiBlock, macro
}

