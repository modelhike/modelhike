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
    private let pInfo: ParsedInfo
    
    public func persist() throws {
        let file = LocalFile(path: outputPath / filename)
                
        if let data = data {
            if let contents = try renderer.renderTemplate(fileName: template, data: data, with: pInfo) {
                try file.write(contents)
            }
        } else {
            if let contents = try renderer.renderTemplate(fileName: template, data: [:], with: pInfo) {
                try file.write(contents)
            }
        }
        
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
