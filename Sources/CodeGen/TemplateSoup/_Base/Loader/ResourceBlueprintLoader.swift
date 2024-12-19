//
// ResourceBlueprintLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class ResourceBlueprintLoader : BlueprintRepository {
    private var templateCache : [String: Template] = [:]
    public let context: Context

    public let blueprintName: String
    let bundle: Bundle
    var resourceRoot: String
    
    public func loadTemplate(fileName: String) throws -> Template {
        if let resourceURL = bundle.url(forResource: fileName,
                                        withExtension: TemplateConstants.TemplateExtension,
                                        subdirectory : resourceRoot ) {
            do {
                let content = try String(contentsOf: resourceURL)
                let template = StringTemplate(contents: content, name: fileName)
                self.templateCache[fileName] = template
                return template
            } catch {
                throw TemplateSoup_EvaluationError.templateReadingError(fileName)
            }
        } else {
            throw TemplateSoup_EvaluationError.templateDoesNotExist(fileName)
        }

    }
    
    public func blueprintExists() -> Bool {
        do {
            let folder = resourceRoot
            guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return false }
            
            let fm = FileManager.default
            let resourcePaths = try fm.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
            
            return resourcePaths.count > 0
        } catch {
            return false
        }
    }
    
    public func hasFolder(_ foldername: String) -> Bool {
        do {
            let folder = resourceRoot + foldername
            guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return false }
            
            let fm = FileManager.default
            let resourcePaths = try fm.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil)
            
            return resourcePaths.count > 0
        } catch {
            return false
        }
    }
    
    public func copyFiles(foldername: String, to outputFolder: LocalFolder) throws {
        let folder = resourceRoot + foldername
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return }
        
        try copyResourceFiles(from: resourceURL, to: outputFolder.path)
    }
    
    fileprivate func copyResourceFiles(from resUrl: URL, to outputPath: LocalPath) throws {
        let fm = FileManager.default
        try outputPath.ensureExists()

        do {
            let resourcePaths = try fm.contentsOfDirectory(at: resUrl, includingPropertiesForKeys: nil)
            for resourcePath in resourcePaths {
                let resourceName = resourcePath.lastPathComponent
                
                if !resourcePath.hasDirectoryPath { //resource file
                    let contents = try String(contentsOf: resourcePath)

                    let filename = resourceName
                    let outFile = LocalFile(path: outputPath / filename)
                    try outFile.write(contents)
                } else { //resource folder
                    let newResUrl = resUrl.appendingPathComponent(resourceName)
                    try copyResourceFiles(from: newResUrl, to: outputPath / resourceName)
                }
            }
        } catch {
            print(error)
            throw ResourceDoesNotExist(resName: resUrl.absoluteString)
        }
    }
    
    public func renderFiles(foldername: String, to outputFolder: LocalFolder, using templateSoup: TemplateSoup) throws {
        let folder = resourceRoot + foldername
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return }
        
        try renderResourceFiles(from: resourceURL, to: outputFolder, using: templateSoup)
    }
    
    fileprivate func renderResourceFiles(from resUrl: URL, to outputFolder: LocalFolder, using templateSoup: TemplateSoup) throws {
        let fm = FileManager.default

        do {
            let resourcePaths = try fm.contentsOfDirectory(at: resUrl, includingPropertiesForKeys: nil)
            for resourcePath in resourcePaths {
                var resourceName = resourcePath.lastPathComponent
                
                if !resourcePath.hasDirectoryPath { //resource file
                    if resourceName.fileExtension() == TemplateConstants.TemplateExtension { //if tempalte file
                        
                        resourceName = resourceName.withoutFileExtension()
                        
                        //render the filename if it has an expression within '{{' and '}}'
                        let filename = try ContentHandler.eval(expression: resourceName, with: templateSoup.context) ?? resourceName
                        
                        //if handler returns false, dont render file
                        if try !context.events.canRender(filename: filename) {
                            continue
                        }
                        
                        let contents = try String(contentsOf: resourcePath)

                        let renderClosure = { outputname in
                            if let renderedString = try templateSoup.renderTemplate(string: contents, identifier: resourceName){
                                
                                //create the folder only if any file is rendered
                                try outputFolder.ensureExists()
                                
                                templateSoup.context.debugLog.generatingFileInFolder(filename, with: resourceName, folder: outputFolder)

                                let ouputFilename: String = outputname.isNotEmpty ? outputname : filename
                                let outFile = LocalFile(path: outputFolder.path / ouputFilename)
                                try outFile.write(renderedString)
                            }
                        }
                        
                        let parsingIdentifier = resourceName
                        if let frontMatter = try templateSoup.frontMatter(in: contents, identifier: parsingIdentifier),
                           let pInfo = frontMatter.hasDirective(ParserDirectives.includeFor) {
                            try templateSoup.forEach(forInExpression: pInfo.line, parser: pInfo.parser) {
                                if let _ = frontMatter.hasDirective(ParserDirectives.outputFilename) {
                                    if let outputFilename = try frontMatter.evalDirective( ParserDirectives.outputFilename, pInfo: pInfo) as? String {
                                        try renderClosure(outputFilename)
                                    }
                                } else {
                                    try renderClosure("")
                                }
                            }
                        } else {
                            try renderClosure("")
                        }
                        
                    } else { //not a template file
                        //create the folder only if any file is copied
                        try outputFolder.ensureExists()
                        
                        let contents = try String(contentsOf: resourcePath)
                        let filename = resourceName

                        templateSoup.context.debugLog.copyingFileInFolder(filename, folder: outputFolder)

                        let outFile = LocalFile(path: outputFolder.path / filename)
                        try outFile.write(contents)
                    }
                } else { //resource folder
                    let subfoldername = try ContentHandler.eval(expression: resourceName, with: templateSoup.context) ?? resourceName
                    
                    let newResUrl = resUrl.appendingPathComponent(subfoldername)
                    try renderResourceFiles(from: newResUrl, to: outputFolder / resourceName, using: templateSoup)
                }
            }
        } catch {
            print(error)
            throw ResourceDoesNotExist(resName: resUrl.absoluteString)
        }
    }
    
    public func readTextContents(filename: String) throws -> String {
        if let resourceURL = bundle.url(forResource: filename,
                                        withExtension: TemplateConstants.TemplateExtension,
                                        subdirectory : resourceRoot ) {
            do {
                let content = try String(contentsOf: resourceURL)
                return content
            } catch {
                throw ResourceReadingError(resName: filename)
            }
        } else {
            throw ResourceDoesNotExist(resName: filename)
        }
    }
    
    public init(blueprint: String, bundle: Bundle, with ctx: Context) {
        self.bundle = bundle
        self.blueprintName = blueprint
        self.resourceRoot = "/Resources/\(blueprint)/"
        self.context = ctx
    }

}

public struct ResourceReadingError : ErrorWithInfo {
    let resName: String
    
    public var info: String {
        return "Resource \(resName) reading error."
    }
    
    public init(resName: String) {
        self.resName = resName
    }
}

public struct ResourceDoesNotExist : ErrorWithInfo {
    let resName: String
    
    public var info: String {
        return "Resource \(resName) does not exist."
    }
    
    public init(resName: String) {
        self.resName = resName
    }
}
