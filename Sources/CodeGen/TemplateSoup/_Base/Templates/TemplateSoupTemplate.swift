//
// TemplateSoupTemplate.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TemplateSoupTemplate : ScriptedTemplate {
    
    private let contents: String
    private var frontMatter: String?
    public let file: LocalFile?
    
    public func toString() -> String {
        contents
    }
    
    public init(contents: String, file: LocalFile) {
        self.contents = contents
        self.file = file
    }
    
    public init(contents: String) {
        self.contents = contents
        self.file = nil
    }
}
