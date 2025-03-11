//
//  OutputDocumentFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public class OutputDocumentFile : OutputFile {
    public let filename: String
    public var outputPath: LocalPath!
    public let doc: Document
    public let fileType : InputFileType
    
    public func render() {
        //TODO: add code
    }
    
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
