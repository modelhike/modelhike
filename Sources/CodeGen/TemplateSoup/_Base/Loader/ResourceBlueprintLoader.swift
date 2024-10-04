//
// ResourceBlueprintLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class ResourceBlueprintLoader : BlueprintRepository {
    private var templateCache : [String: Template] = [:]

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
        
        try renderResourceFiles(from: resourceURL, to: outputFolder.path, using: templateSoup)
    }
    
    fileprivate func renderResourceFiles(from resUrl: URL, to outputPath: LocalPath, using templateSoup: TemplateSoup) throws {
        let fm = FileManager.default
        try outputPath.ensureExists()

        do {
            let resourcePaths = try fm.contentsOfDirectory(at: resUrl, includingPropertiesForKeys: nil)
            for resourcePath in resourcePaths {
                var resourceName = resourcePath.lastPathComponent
                
                if !resourcePath.hasDirectoryPath { //resource file
                    let contents = try String(contentsOf: resourcePath)

                    if resourceName.fileExtension() == TemplateConstants.TemplateExtension { //if tempalte file
                        
                        resourceName = resourceName.withoutFileExtension()
                        
                        //render the filename if it has an expression within '{{' and '}}'
                        let filename = try ContentLine.eval(line: resourceName, with: templateSoup.context) ?? resourceName
                        
                        let renderClosure = {
                            if let renderedString = try templateSoup.renderTemplate(string: contents, identifier: resourceName){
                                
                                let outFile = LocalFile(path: outputPath / filename)
                                try outFile.write(renderedString)
                            }
                        }
                        
                        if let pctx = templateSoup.frontMatter(hasDirective: ParserDirectives.includeFor, in: contents, identifier: resourceName) {
                            try templateSoup.forEach(forInExpression: pctx.line, parser: pctx.parser, renderClosure: renderClosure)
                        } else {
                            try renderClosure()
                        }
                        
                    } else { //not a template file

                        let filename = resourceName
                        let outFile = LocalFile(path: outputPath / filename)
                        try outFile.write(contents)
                    }
                } else { //resource folder
                    let subfoldername = try ContentLine.eval(line: resourceName, with: templateSoup.context) ?? resourceName
                    
                    let newResUrl = resUrl.appendingPathComponent(subfoldername)
                    try renderResourceFiles(from: newResUrl, to: outputPath / resourceName, using: templateSoup)
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
    }

}

public struct ResourceReadingError : Error {
    let resName: String
    
    public init(resName: String) {
        self.resName = resName
    }
}

public struct ResourceDoesNotExist : Error {
    let resName: String
    
    public init(resName: String) {
        self.resName = resName
    }
}
