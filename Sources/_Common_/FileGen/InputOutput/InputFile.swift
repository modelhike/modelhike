//
// InputFile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct InputFile {
    public let filename: String
    public let doc: Document
    public let fileType : InputFileType
    
    public init(_ doc: Document, filename: String, type: InputFileType = .generic) {
        self.filename = filename
        self.doc = doc
        self.fileType = type
    }
    
    public enum InputFileType {
        case generic, content, markup, asset
    }
}

