//
// Method.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct Method : CodeMember {
    public var attribs = Attributes()
    public var tags = Tags()

    public var name: String
    public var returnType : ReturnType
    
    public var body : StringTemplate
    
    public init(_ name: String, returnType: ReturnType = .void, @StringConvertibleBuilder _ body: () -> [StringConvertible]) {
        self.name = name.normalizeForVariableName()
        self.returnType = returnType
        self.body = StringTemplate(body)
    }
}

public enum ReturnType {
    case void, int, double, bool, string, customType(String)
}
