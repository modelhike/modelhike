//
//  OutputFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol PersistableFile {
    var filename: String {get}
    func persist() throws
}

public protocol OutputFile : AnyObject, PersistableFile {
    var outputPath: LocalPath! {get set}
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
