//
// ResourceTemplateLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class ResourceTemplateLoader : TemplateRepository {
    private var templateCache : [String: TemplateSoupTemplate] = [:]

    let bundle: Bundle
    var resourceRoot: String
    
    public func loadTemplate(fileName: String) throws -> TemplateSoupTemplate {
        if let resourceURL = bundle.url(forResource: fileName,
                                        withExtension: TemplateConstants.TemplateExtension,
                                        subdirectory : resourceRoot ) {
            do {
                let content = try String(contentsOf: resourceURL)
                let template = TemplateSoupTemplate(contents: content)
                self.templateCache[fileName] = template
                return template
            } catch {
                throw TemplateReadingError(templateName: fileName)
            }
        } else {
            throw TemplateDoesNotExist(templateName: fileName)
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
    
    public init(command: String, bundle: Bundle, with ctx: Context) {
        self.bundle = bundle
        self.resourceRoot = "/Resources/\(command)/"
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
