//
// PlaceHolderFile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class PlaceHolderFile : OutputFile {
    private let oldFilename: String
    public let filename: String
    private let repo: InputFileRepository
    public var outputPath: LocalPath!
    let renderer: TemplateRenderer
    
    public func persist() throws {
        let inFileContents = try repo.readTextContents(filename: self.oldFilename)
        
        let data : [String: Any] = [:]
        let contents = try renderer.renderTemplate(string: inFileContents, data: data) ?? ""
        
        let outFile = LocalFile(path: outputPath / filename)
        try outFile.write(contents)
    }
    
    public init(filename: String, repo: InputFileRepository, to newFileName: String, path outFilePath: LocalPath, renderer: TemplateRenderer) {
        self.oldFilename = filename
        self.filename = newFileName

        self.repo = repo
        self.outputPath = outFilePath
        self.renderer = renderer
    }
    
}
