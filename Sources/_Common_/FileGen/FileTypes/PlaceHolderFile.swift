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
    let pInfo: ParsedInfo
    public func persist() throws {
        let data : [String: Any] = [:]
        
        if let contents = try renderer.renderTemplate(fileName: self.oldFilename, data: data, with: pInfo) {
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
