//
// LocalFileBlueprintLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LocalFileBlueprintLoader: BlueprintRepository {
    private var templateCache : [String: Template] = [:]
    public let defaultTemplatesPath: LocalPath
    public let context: Context
    public var paths: [LocalPath]
    public let blueprintName: String
    
    public func loadTemplate(fileName: String, pInfo: ParsedInfo) throws -> Template {
        for loadPath in paths {
            let templateName = "\(fileName).\(TemplateConstants.TemplateExtension)"

            let templatePath = loadPath / templateName

            if !templatePath.exists { continue } //check if found in next oath

            let file = LocalFile(path: templatePath )

            if let template = LocalFileTemplate(file: file) {
                self.templateCache[fileName] = template
                return template
            } else {
                throw TemplateSoup_EvaluationError.templateReadingError(fileName, pInfo)
            }
        }

        throw TemplateSoup_EvaluationError.templateDoesNotExist(fileName, pInfo)
    }
    
    public func blueprintExists() -> Bool {
        return self.defaultTemplatesPath.exists
    }
    
    public func hasFolder(_ foldername: String) -> Bool {
        guard self.defaultTemplatesPath.exists else {
            return false
        }
        
        let inFolder = LocalFolder(path: self.defaultTemplatesPath / foldername)
        return inFolder.path.exists
    }
    
    public func copyFiles(foldername: String, to outputFolder: LocalFolder, pInfo: ParsedInfo) throws {
        guard self.defaultTemplatesPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.defaultTemplatesPath.string)", pInfo)
        }
        
        do {
            let inFolder = LocalFolder(path: self.defaultTemplatesPath / foldername)
            try inFolder.copyFiles(to: outputFolder)
        } catch let err {
            if let _ = err as? ErrorWithMessageAndParsedInfo {
                throw err
            } else {
                let message = "Could not copy files from \(foldername) to \(outputFolder.path.string)"
                throw EvaluationError.failedWriteOperation(message, pInfo)
            }
        }
    }
    
    public func renderFiles(foldername: String, to outputFolder: LocalFolder, using templateSoup: TemplateSoup, pInfo: ParsedInfo) throws {
        guard self.defaultTemplatesPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.defaultTemplatesPath.string)", pInfo)
        }
        
        do {
            let inFolder = LocalFolder(path: self.defaultTemplatesPath / foldername)
            
            try renderLocalFiles(from: inFolder, to: outputFolder, using: templateSoup)
        } catch let err {
            if let _ = err as? ErrorWithMessageAndParsedInfo {
                throw err
            } else {
                let message = "Could not render files from \(foldername) to \(outputFolder.path.string)"
                throw EvaluationError.failedWriteOperation(message, pInfo)
            }
        }
    }
    
    private func renderLocalFiles(from inFolder: LocalFolder, to outputFolder: LocalFolder, using templateSoup: TemplateSoup) throws {
                
        let files = inFolder.files
        
        for file in files {
            if file.extension == TemplateConstants.TemplateExtension { //template file
                let actualFilename = file.nameExcludingExtension
                
                //render the filename if it has an expression within '{{' and '}}'
                let filename = try ContentHandler.eval(expression: actualFilename, with: templateSoup.context) ?? actualFilename
                
                //if handler returns false, dont render file
                if try !context.events.canRender(filename: filename) {
                    continue
                }
                
                let contents = try file.readTextContents()
                
                let renderClosure = { outputname, pInfo in
                    if let renderedString = try templateSoup.renderTemplate(string: contents, identifier: actualFilename, pInfo: pInfo) {
                        
                        //create the folder only if any file is rendered
                        try outputFolder.ensureExists()

                        templateSoup.context.debugLog.generatingFileInFolder(filename, with: actualFilename, folder: outputFolder)

                        let ouputFilename: String = outputname.isNotEmpty ? outputname : filename
                        let outFile = LocalFile(path: outputFolder.path / ouputFilename)
                        try outFile.write(renderedString)
                    }
                }
                
                let parsingIdentifier = actualFilename
                if let frontMatter = try templateSoup.frontMatter(in: contents, identifier: parsingIdentifier),
                   let pInfo = frontMatter.hasDirective(ParserDirective.includeFor) {
                    try templateSoup.forEach(forInExpression: pInfo.line, pInfo: pInfo) {
                        if let _ = frontMatter.hasDirective(ParserDirective.outputFilename) {
                            if let outputFilename = try frontMatter.evalDirective( ParserDirective.outputFilename, pInfo: pInfo) as? String {
                                try renderClosure(outputFilename, pInfo)
                            }
                        } else {
                            try renderClosure("", pInfo)
                        }
                    }
                } else {
                    let pInfo = ParsedInfo.dummyForFrontMatterError(identifier: parsingIdentifier, with: context)
                    try renderClosure("", pInfo)
                }
                
            } else { //not a template file
                //create the folder only if any file is copied
                try outputFolder.ensureExists()
                
                templateSoup.context.debugLog.copyingFileInFolder(file.name, folder: outputFolder)

                try file.copy(to: outputFolder)
            }
        }
        
        //copy files from subfolders also
        for subFolder in inFolder.subFolders {
            let subfoldername = try ContentHandler.eval(expression: subFolder.name, with: templateSoup.context) ?? subFolder.name
            
            let newFolder = outputFolder / subfoldername
            try renderLocalFiles(from: subFolder, to: newFolder, using: templateSoup)
        }
        
    }
    
    public func readTextContents(filename: String, pInfo: ParsedInfo) throws -> String {
        guard self.defaultTemplatesPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.defaultTemplatesPath.string)", pInfo)
        }
        
        let inFile = LocalFile(path: self.defaultTemplatesPath / filename)
        let inFileContents = try inFile.readTextContents()
        return inFileContents
    }
    
    public init(blueprint: String, path templatesPath: LocalPath, with ctx: Context) {
        let path = templatesPath / blueprint

        self.paths = [path]
        self.context = ctx
        self.defaultTemplatesPath = path
        self.blueprintName = blueprint
    }
    
    internal init(path: LocalPath, with ctx: Context) {
        self.paths = [path]
        self.context = ctx
        self.defaultTemplatesPath = path
        self.blueprintName = ""
    }
    
    public func add(paths: LocalPath...) {
        self.paths.append(contentsOf: paths)
    }
    
    public func add(paths: [LocalPath]) {
        self.paths.append(contentsOf: paths)
    }
}

