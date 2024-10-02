//
// StringTemplate.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct StringTemplate : Template, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {   
    public var name: String = "string"
    
    var items: [StringConvertible]
    
    @discardableResult
    mutating func append(_ item: StringConvertible) -> Self {
        items.append(item)
        return self
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
    
    public init(contents: String, name: String) {
        self.items = [contents]
        self.name = name
    }
    
    static func +(lhs: StringTemplate, rhs: any StringConvertible) -> StringTemplate {
        var newLhs = lhs
        newLhs.append(rhs)
        return newLhs
    }
    
    static func +(lhs: any StringConvertible, rhs: StringTemplate) -> StringTemplate {
        var newRhs = rhs
        newRhs.append(lhs)
        return newRhs
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
    static func +=(lhs: inout StringTemplate, rhs: String) {
        lhs.append(rhs)
    }
    
    static func +=(lhs: inout String, rhs: StringTemplate){
        lhs += rhs.toString()
    }
}
