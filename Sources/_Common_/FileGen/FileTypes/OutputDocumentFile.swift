//
//  OutputDocumentFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class OutputDocumentFile : OutputFile, RenderableFile {
    public let filename: String
    private let doc: Document
    private let renderConfig: RenderConfig

    public var outputPath: LocalPath?
    var contents: String? = nil
    
    public let fileType : InputFileType

    public func render() throws {
        self.contents = try doc.render(renderConfig)
    }
    
    public func persist() throws {
                
        if let outputPath {
            if let contents { //save only if there is a content
                let file = LocalFile(path: outputPath / filename)
                try file.write(contents)
            }
        } else {
            fatalError(#function + ": output path not set!")
        }
    }
    
    public var debugDescription: String {
        if let outputPath {
            let outFile = LocalFile(path: outputPath / filename)
            return outFile.pathString
        } else {
            return "Doc RenderedFile: \(filename)"
        }
    }
    
    public init(_ doc: Document, filename: String, renderConfig: RenderConfig, type: InputFileType = .generic) {
        self.filename = filename
        self.doc = doc
        self.outputPath = nil
        self.renderConfig = renderConfig
        self.fileType = type
    }
    
    public enum InputFileType {
        case generic, content, markup, asset
    }
}
