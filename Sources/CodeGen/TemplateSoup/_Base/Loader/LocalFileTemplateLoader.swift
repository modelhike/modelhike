//
// LocalFileTemplateLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LocalFileTemplateLoader: TemplateRepository {
    private var templateCache : [String: TemplateSoupTemplate] = [:]
    public let defaultTemplatesPath: LocalPath
    public let context: Context
    public var paths: [LocalPath]

    public func loadTemplate(fileName: String) throws -> TemplateSoupTemplate {
        for loadPath in paths {
            let templateName = "\(fileName).\(TemplateConstants.TemplateExtension)"

            let templatePath = loadPath / templateName

            if !templatePath.exists { continue } //check if found in next oath

            let file = LocalFile(path: templatePath )

            if let content: String = try? file.readTextContents() {
                let template = TemplateSoupTemplate(contents: content, file: file)
                self.templateCache[fileName] = template
                return template
            } else {
                throw TemplateReadingError(templateName: fileName)
            }
        }

        throw TemplateDoesNotExist(templateName: fileName)
    }
    
    public func copyFiles(foldername: String, to outputFolder: LocalFolder) throws {
        guard self.defaultTemplatesPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.defaultTemplatesPath.string)")
        }
        
        let inFolder = LocalFolder(path: self.defaultTemplatesPath / foldername)
        try inFolder.copyFiles(to: outputFolder)
    }
    
    public func readTextContents(filename: String) throws -> String {
        guard self.defaultTemplatesPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.defaultTemplatesPath.string)")
        }
        
        let inFile = LocalFile(path: self.defaultTemplatesPath / filename)
        let inFileContents = try inFile.readTextContents()
        return inFileContents
    }
    
    public init(command: String, path templatesPath: LocalPath, with ctx: Context) {
        let path = templatesPath / command

        self.paths = [path]
        self.context = ctx
        self.defaultTemplatesPath = path
    }
    
    public init(path: LocalPath, with ctx: Context) {
        self.paths = [path]
        self.context = ctx
        self.defaultTemplatesPath = path
    }
    
    public func add(paths: LocalPath...) {
        self.paths.append(contentsOf: paths)
    }
    
    public func add(paths: [LocalPath]) {
        self.paths.append(contentsOf: paths)
    }
}

