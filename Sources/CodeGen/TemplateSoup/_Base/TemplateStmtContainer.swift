//
// TemplateStmtContainer.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol TemplateStmtContainer : IteratorProtocol, Sequence, CustomDebugStringConvertible {
    func append(_ item: FileTemplateItem)
}

public class GenericStmtsContainer : TemplateStmtContainer {
    
    public var kind: TemplateStmtContainerKind = .global
    public var name: String?
    
    var items : [FileTemplateItem] = []
    public var isEmpty: Bool { items.count == 0 }
    var count: Int { items.count }
    private var currentIndex = 0

    public func append(_ item: FileTemplateItem) {
        items.append(item)
    }
    
    public func next() -> FileTemplateItem? {
        if currentIndex <= items.count - 1 {
            let compo = items[currentIndex]
            currentIndex += 1
            return compo
        } else {
            currentIndex = 0 //reset index
            return nil
        }
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

public enum TemplateStmtContainerKind {
    case global, partOfMultiBlock, macro
}

