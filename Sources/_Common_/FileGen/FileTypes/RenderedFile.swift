//
//  RenderedFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

open class RenderedFile : RenderableFile {
    public let filename: String
    private let template: String?
    public var outputPath: LocalPath!
    private let data: [String: Any]?
    private let renderer: TemplateRenderer?
    private let pInfo: ParsedInfo
    var contents: String? = nil

    public func render() throws {
        guard let renderer = renderer, let template = template else { return }
        
        if let data = data {
            if let contents = try renderer.renderTemplate(fileName: template, data: data, with: pInfo) {
                self.contents = contents
            }
        } else {
            if let contents = try renderer.renderTemplate(fileName: template, data: [:], with: pInfo) {
                self.contents = contents
            }
        }
        
    }
    
    public func persist() throws {
        let file = LocalFile(path: outputPath / filename)
                
        if let contents = contents {
            try file.write(contents)
        }
        
    }
    
    public init(filename: String, filePath: LocalPath, contents: String, pInfo: ParsedInfo) {
        self.filename = filename
        self.outputPath = filePath
        self.contents = contents
        self.pInfo = pInfo
        
        self.data = nil
        self.renderer = nil
        self.template = nil
    }
    
    public init(filename: String, filePath: LocalPath, template: String, data: [String: Any]? = nil, renderer: TemplateRenderer, pInfo: ParsedInfo) {
        self.filename = filename
        self.template = template
        self.data = data
        self.renderer = renderer
        self.outputPath = filePath
        self.pInfo = pInfo
    }
    
}
