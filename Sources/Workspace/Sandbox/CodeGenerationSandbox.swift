//
// CodeGenerationSandbox.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class CodeGenerationSandbox : Sandbox, FileGeneratorProtocol {
    public private(set) var templateSoup: TemplateSoup
    public private(set) var generation_dir: LocalPath
    
    public let model: AppModel
    
    public var basePath: LocalPath { context.paths.basePath }
    public var outputPath: LocalPath { context.paths.output.path }

    public let context: Context
    
    public var onLoadTemplate : LoadTemplateHandler {
        get { templateSoup.onLoadTemplate }
        set { templateSoup.onLoadTemplate = newValue }
    }
    
    var lineParser : LineParser
    
    public func generateFilesFor(container: String, usingBlueprintsFrom templateLoader: BlueprintRepository) throws -> String? {
        guard let container = model.container(named: container) else {
            throw EvaluationError.invalidInput("There is no container called \(container)")
        }
        
        let variables = container.toDictionary(using: model)
        self.context.replace(variables: variables)
        
        self.templateSoup.repo = templateLoader
        
        return try templateSoup.renderTemplateWithFrontMatter(fileName: "main")
    }
    
    public func renderTemplate(string templateString: String, data: [String: Any]) throws -> String? {
        
        return try templateSoup.renderTemplate(string: templateString, data: data)
    }
    
    public init(context: Context) {
        self.context = context
        self.lineParser  = LineParser(context: context)

        self.model = AppModel()
        
        self.templateSoup  = TemplateSoup(context: context)

        self.generation_dir = context.paths.output.path
        
        context.fileGenerator = self

    }
}

public extension CodeGenerationSandbox  { //file generation protocol
        
    func setRelativePath(_ path: String) throws {
        generation_dir = context.paths.output.path / path
        try generation_dir.ensureExists()
    }
    
    func generateFile(_ filename: String, template: String) throws -> RenderedFile {
        let file = RenderedFile(filename: filename, filePath: generation_dir, template: template, renderer: self.templateSoup)
        try file.persist()
        return file
    }
    
    func generateFileWithData(_ filename: String, template: String, data: [String: Any]) throws -> RenderedFile {
        let file = RenderedFile(filename: filename, filePath: generation_dir, template: template, data: data, renderer: self.templateSoup)
        try file.persist()
        return file
    }
    
    func copyFile(_ filename: String) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir)
        try file.persist()
        return file
    }
        
    func copyFile(_ filename: String, to newFilename: String) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir)
        try file.persist()
        return file
    }
    
    func copyFolder(_ foldername: String) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: foldername, path: generation_dir)
        try folder.copyFiles()
        return folder
    }
    
    func copyFolder(_ foldername: String, to newPath: String) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: newPath, path: generation_dir)
        try folder.copyFiles()
        return folder
    }
    
    func fillPlaceholdersAndCopyFile(_ filename: String) throws -> PlaceHolderFile {
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir, renderer: self.templateSoup)
        try file.persist()
        return file
    }

    func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String) throws -> PlaceHolderFile {
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir, renderer: self.templateSoup)
        try file.persist()
        return file
    }
}
