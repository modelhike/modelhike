//
// RenderedFile.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class RenderedFile : OutputFile {
    public let filename: String
    private let template: String
    public var outputPath: LocalPath!
    private let data: [String: Any]?
    private let renderer: TemplateRenderer
    
    public func persist() throws {
        let file = LocalFile(path: outputPath / filename)
        
        var contents = ""
        
        if let data = data {
            contents = try renderer.renderTemplateWithoutFrontMatter(fileName: template, data: data) ?? ""
        } else {
            contents = try renderer.renderTemplateWithoutFrontMatter(fileName: template, data: [:]) ?? ""
        }
        
        try file.write(contents)
    }
    
    public init(filename: String, filePath: LocalPath, template: String, data: [String: Any]? = nil, renderer: TemplateRenderer) {
        self.filename = filename
        self.template = template
        self.data = data
        self.renderer = renderer
        self.outputPath = filePath
    }
    
}
