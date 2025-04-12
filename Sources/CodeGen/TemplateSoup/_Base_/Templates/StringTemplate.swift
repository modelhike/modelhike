//
//  StringTemplate.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct StringTemplate : Template, Script, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public var name: String = "string"
    
    let items: [StringConvertible]
    
    @discardableResult
    static func append(_ obj: StringTemplate, with item: StringConvertible) -> Self {
        var newItems = obj.items
        newItems.append(item)
        return StringTemplate(contentsOf: newItems)
    }
    
    public func toString() -> String {
        return items.reduce("") { $0 + $1.toString() }
    }
    
    public var string: String { toString() }

    public init(@StringConvertibleBuilder _ builder : () -> [StringConvertible]) {
        items = builder()
    }
    
    public init(stringLiteral value: String) {
        items = [value]
    }
    
    public init(stringInterpolation: String) {
        items = [stringInterpolation]
    }
    
    public init(_ value: String) {
        items = [value]
    }
    
    public init(contentsOf value: [StringConvertible]) {
        items = value
    }
    
    public init(contents: String, name: String) {
        self.items = [contents]
        self.name = name
    }
    
    static func +(lhs: StringTemplate, rhs: any StringConvertible) -> StringTemplate {
        return StringTemplate.append(lhs, with: rhs)
    }
    
    static func +(lhs: any StringConvertible, rhs: StringTemplate) -> StringTemplate {
        return StringTemplate.append(rhs, with: lhs)

    }
}

public struct TabChar : StringConvertible {
    let linesCount: Int
    static public let characters = "\t"
    
    public func toString() -> String {
        var str = ""
        
        for _ in 1...linesCount {
            str += Self.characters
        }
        
        return str
    }
    
    public init(_ lines: Int) {
        self.linesCount = lines
    }
    
    public init() {
        self.linesCount = 1
    }
}

public extension String {
    static func +=(lhs: inout StringTemplate, rhs: String) -> StringTemplate {
        return StringTemplate.append(lhs, with: rhs)
    }
    
    static func +=(lhs: inout String, rhs: StringTemplate) -> StringTemplate {
        return StringTemplate.append(rhs, with: lhs)
    }
}
