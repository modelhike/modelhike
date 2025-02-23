//
// LocalFilesetTemplate.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct LocalFilesetTemplate : ScriptedTemplate {
    public private(set) var name: String
    public let files: [LocalFile]
    
    public func toString() -> String {
        name
    }
    
    public init(folderPath: String) {
        let folder = LocalFolder(path: folderPath)

        self.files = folder.files
        self.name = folder.name
    }
}
