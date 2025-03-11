//
//  PlaceHolderFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class PlaceHolderFile : OutputFile {
    private let oldFilename: String
    public let filename: String
    private let repo: InputFileRepository
    public var outputPath: LocalPath!
    let renderer: TemplateRenderer
    let pInfo: ParsedInfo
    var contents: String? = nil
    
    public func render() throws {
        let data : [String: Any] = [:]
        
        if let contents = try renderer.renderTemplate(fileName: self.oldFilename, data: data, with: pInfo) {
            self.contents = contents
        }
    }
    
    public func persist() throws {        
        if let contents = contents {
            let outFile = LocalFile(path: outputPath / filename)
            try outFile.write(contents)
        }
    }
    
    public init(filename: String, repo: InputFileRepository, to newFileName: String, path outFilePath: LocalPath, renderer: TemplateRenderer, pInfo: ParsedInfo) {
        self.oldFilename = filename
        self.filename = newFileName

        self.repo = repo
        self.outputPath = outFilePath
        self.renderer = renderer
        self.pInfo = pInfo
    }
    
}
