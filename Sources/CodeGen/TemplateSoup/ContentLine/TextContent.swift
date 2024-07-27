//
// TextContent.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class TextContent: ContentLineItem {
    let content : String
    let lineNo: Int
    let level: Int
    
    public func execute(with ctx: Context) throws -> String? {
        return content
    }
    
    public var debugDescription: String { content }
    
    
    public init(_ content: String, lineNo: Int, level: Int) {
        self.content = content
        self.lineNo = lineNo
        self.level = level
    }
}
