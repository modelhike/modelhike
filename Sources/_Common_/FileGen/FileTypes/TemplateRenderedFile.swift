//
//  TemplateRenderedFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct TemplateRenderedFile : OutputFile, RenderableFile {
    public let filename: String
    private let template: String?
    public var outputPath: LocalPath?
    private let data: [String: Sendable]?
    private let renderer: TemplateRenderer?
    private let pInfo: ParsedInfo
    var contents: String? = nil

    public mutating func render() async throws {
        guard let renderer = renderer, let template = template else { return }
        
        if let data = data {
            if let contents = try await renderer.renderTemplate(fileName: template, data: data, with: pInfo) {
                self.contents = contents
            }
        } else {
            if let contents = try await renderer.renderTemplate(fileName: template, data: [:], with: pInfo) {
                self.contents = contents
            }
        }
        
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
            return "Template RenderedFile: \(filename)"
        }
    }
    
    public init(filename: String, contents: String, pInfo: ParsedInfo) {
        self.filename = filename
        self.outputPath = nil
        self.contents = contents
        self.pInfo = pInfo
        
        self.data = nil
        self.renderer = nil
        self.template = nil
    }
    
//    public init(filename: String, filePath: LocalPath, contents: String, pInfo: ParsedInfo) {
//        self.filename = filename
//        self.outputPath = filePath
//        self.contents = contents
//        self.pInfo = pInfo
//        
//        self.data = nil
//        self.renderer = nil
//        self.template = nil
//    }
    
    public init(filename: String, template: String, data: [String: Sendable]? = nil, renderer: TemplateRenderer, pInfo: ParsedInfo) {
            self.filename = filename
            self.template = template
            self.data = data
            self.renderer = renderer
            self.outputPath = nil
            self.pInfo = pInfo
        }
    
//    public init(filename: String, filePath: LocalPath, template: String, data: [String: Any]? = nil, renderer: TemplateRenderer, pInfo: ParsedInfo) {
//        self.filename = filename
//        self.template = template
//        self.data = data
//        self.renderer = renderer
//        self.outputPath = filePath
//        self.pInfo = pInfo
//    }
    
}
