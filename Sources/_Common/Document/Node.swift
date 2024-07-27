//
// Node.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Node {
    var attributes: Attributes {get set}
    //func name() -> String
    func render(_ config: RenderConfig, level: Int) -> String
}

public protocol ContainerNode: Node, ExpressibleByArrayLiteral {
    
}

public protocol RestrictedContainerNode: Node {
    
}

public protocol LeafNode: Node, ExpressibleByStringLiteral {
    
}

public protocol LiteralNode: Node, ExpressibleByStringLiteral {
    var text: String {get}
}

public protocol LayoutNode: Node {
    
}

public protocol RenderAsBlock {
    
}

public protocol RenderInline {
    
}

public extension LiteralNode {
    func render(_ config: RenderConfig, level: Int) -> String {
        return text
    }
}

public extension Node {
    @discardableResult
    mutating func attributeIf(_ key: String, value: String?, condition: Bool) -> Self {
        if condition, let value = value {
            attributes[key] = value
        }
        
        return self
    }
    
    func render(_ config: RenderConfig) -> String {
        render(config, level: 0)
    }
}
