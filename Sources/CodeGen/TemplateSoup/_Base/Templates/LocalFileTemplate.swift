//
// LocalFileTemplate.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct LocalFileTemplate : ScriptedTemplate {
    public private(set) var name: String
    private let contents: String
    public let file: LocalFile
    
    public func toString() -> String {
        contents
    }
    
    public init?(file: LocalFile) {
        do {
            self.contents = try file.readTextContents()
            self.file = file
            self.name = file.name
        }
        catch { return nil }
    }
    
}

public protocol FileTemplateStatement : TemplateItemWithParsedInfo {
}

public protocol FileTemplateStmtConfig : TemplateItemConfig {
    
}
