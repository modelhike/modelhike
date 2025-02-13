//
// CodeGenerationSandbox.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class CodeGenerationSandbox : Sandbox, FileGeneratorProtocol {
    public private(set) var templateSoup: TemplateSoup
    public private(set) var generation_dir: LocalPath
    
    public var model: AppModel { context.model }
    
    public var basePath: LocalPath { context.paths.basePath }
    public var outputPath: LocalPath { context.paths.output.path }

    public let context: Context
    var lineParser : LineParser

    //MARK: event handlers
    public var onLoadTemplate : LoadTemplateHandler {
        get { templateSoup.onLoadTemplate }
        set { templateSoup.onLoadTemplate = newValue }
    }
    
    //MARK: Generation code
    public func generateFilesFor(container: String, usingBlueprintsFrom blueprintLoader: BlueprintRepository) throws -> String? {
        
        if try !blueprintLoader.blueprintExists() {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidInput("There is no blueprint called \(blueprintLoader.blueprintName)", pInfo)
        }
        
        guard let container = model.container(named: container) else {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidInput("There is no container called \(container)", pInfo)
        }
                
        let variables : [String: Any] = [
            "@container" : C4Container_Wrap(container, model: model),
            "mock" : Mocking_Wrap()
        ]
        
        self.context.append(variables: variables)

        self.templateSoup.repo = blueprintLoader
        
        context.setWorkingDirectory("/")
        try self.setRelativePath("")
        
        let pInfo = ParsedInfo.dummyForMainFile(with: context)
        
        //handle special folders
        if blueprintLoader.hasFolder(SpecialFolderNames.root) {
            let specialActivity = SpecialActivityCallStackItem(activityName: "Rendering Root Folder")
            context.pushCallStack(specialActivity)

            try renderSpecialFolder(SpecialFolderNames.root, to: "/", pInfo: pInfo)
            context.popCallStack()

        } else {
            print("⚠️ Didn't find 'Root' folder in Blueprint !!!")
        }
        
        return try templateSoup.renderTemplate(fileName: TemplateConstants.MainTemplateFile, with: pInfo)
    }
    
    
    @discardableResult
    private func renderSpecialFolder(_ fromFolder: String, to toFolder: String, msg: String = "", pInfo: ParsedInfo) throws -> RenderedFolder {
        if msg.isNotEmpty {
            print(msg)
        }
        
        context.debugLog.renderingFolder(fromFolder, to: toFolder)
        let folder = try context.fileGenerator.renderFolder(fromFolder, to: toFolder, with: pInfo)
        return folder
    }
    
    public func renderTemplate(string templateString: String, data: [String: Any]) throws -> String? {
        let pInfo = ParsedInfo.dummyForMainFile(with: context)

        return try templateSoup.renderTemplate(string: templateString, data: data, with: pInfo)
    }
    
    public init(context: Context) {
        self.context = context
        self.lineParser  = LineParser(identifier: "-", with: context)
        
        self.templateSoup  = TemplateSoup(context: context)

        self.generation_dir = context.paths.output.path
        
        context.fileGenerator = self

    }
    
    //MARK: File generation protocol
        
    public func setRelativePath(_ path: String) throws {
        generation_dir = context.paths.output.path / path
        try generation_dir.ensureExists()
    }
    
    public func generateFile(_ filename: String, template: String, with pInfo: ParsedInfo) throws -> RenderedFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = RenderedFile(filename: filename, filePath: generation_dir, template: template, renderer: self.templateSoup, pInfo: pInfo)
        try file.persist()
        return file
    }
    
    public func generateFileWithData(_ filename: String, template: String, data: [String: Any], with pInfo: ParsedInfo) throws -> RenderedFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = RenderedFile(filename: filename, filePath: generation_dir, template: template, data: data, renderer: self.templateSoup, pInfo: pInfo)
        try file.persist()
        return file
    }
    
    public func copyFile(_ filename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir, pInfo: pInfo)
        try file.persist()
        return file
    }
        
    public func copyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> StaticFile {
        let file = StaticFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir, pInfo: pInfo)
        try file.persist()
        return file
    }
    
    public func copyFolder(_ foldername: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: foldername, path: generation_dir, pInfo: pInfo)
        try folder.copyFiles()
        return folder
    }
    
    public func copyFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> StaticFolder {
        let folder = StaticFolder(foldername: foldername, repo: templateSoup.repo, to: newPath, path: generation_dir, pInfo: pInfo)
        try folder.copyFiles()
        return folder
    }
    
    public func renderFolder(_ foldername: String, to newPath: String, with pInfo: ParsedInfo) throws -> RenderedFolder {
        //While rendering folder, onBeforeRenderFile is handled within the folder-rendering function
        //This is possibleas onBeforeRenderFile is part of templateSoup
        let folder = RenderedFolder(foldername: foldername, templateSoup: templateSoup, to: newPath, path: generation_dir, pInfo: pInfo)
        try folder.renderFiles()
        return folder
    }
    
    public func fillPlaceholdersAndCopyFile(_ filename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: filename, path: generation_dir, renderer: self.templateSoup, pInfo: pInfo)
        try file.persist()
        return file
    }

    public func fillPlaceholdersAndCopyFile(_ filename: String, to newFilename: String, with pInfo: ParsedInfo) throws -> PlaceHolderFile? {
        if try !context.events.canRender(filename: filename, with: pInfo) { //if handler returns false, dont render file
            return nil
        }
        
        let file = PlaceHolderFile(filename: filename, repo: templateSoup.repo, to: newFilename, path: generation_dir, renderer: self.templateSoup, pInfo: pInfo)
        try file.persist()
        return file
    }
}
