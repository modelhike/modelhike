//
// Document.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol Document {
    func render(_ config: RenderConfig) -> String
}

public protocol ContentDocument : Document {
    
}

public protocol MarkupDocument : Document {
    
}

public struct RenderConfig {
    public let minify: Bool
    public let indentationCount: Int
    public let newline: String
    
    public func indentationSpacing(level: Int) -> String {
        return String(repeating: " ", count: level * indentationCount)
    }

    public init(minify: Bool = false, indentationCount: Int = 4) {
        self.minify = minify
        self.indentationCount = minify ? 0 : indentationCount
        self.newline = minify ? "" : "\n"
    }
    
    public static let pretty = RenderConfig(minify: false, indentationCount: 2)

}
