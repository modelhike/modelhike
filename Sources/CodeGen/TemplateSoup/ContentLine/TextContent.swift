//
//  TextContent.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class TextContent: ContentLineItem {
    let content : String
    public let pInfo: ParsedInfo
    let level: Int
    
    public func execute(with ctx: Context) throws -> String? {
        return content
    }
    
    public var debugDescription: String { content }
    
    
    public init(_ content: String, pInfo: ParsedInfo, level: Int) {
        self.content = content
        self.pInfo = pInfo
        self.level = level
    }
}
