//
// OutputFile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol OutputFile : AnyObject {
    var filename: String {get}
    var outputPath: LocalPath! {get set}
    func persist() throws
}

public class OutputDocumentFile : OutputFile {
    public let filename: String
    public var outputPath: LocalPath!
    public let doc: Document
    public let fileType : InputFileType
    
    public func persist() {
        //TODO: add code
    }
    
    public init(_ doc: Document, filename: String, type: InputFileType = .generic) {
        self.filename = filename
        self.doc = doc
        self.fileType = type
    }
    
    public enum InputFileType {
        case generic, content, markup, asset
    }
}
