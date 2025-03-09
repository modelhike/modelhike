//
// LocalFileBlueprintLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LocalFileBlueprintLoader: Blueprint {
    private var templateCache : [String: Template] = [:]
    private var scriptFileCache : [String: Script] = [:]

    public let blueprintPath: LocalPath
    public let rootPath: LocalPath
    public let context: GenerationContext
    public var paths: [LocalPath]
    public let blueprintName: String
    
    public func loadScriptFile(fileName: String, with pInfo: ParsedInfo) throws -> any Script {
        for loadPath in paths {
            if !loadPath.exists {
                let pInfo = ParsedInfo.dummyForAppState(with: context)
                throw EvaluationError.invalidAppState("Blueprint folder '\(loadPath.string)' not found!!!", pInfo)
            }
            
            let scriptFileName = "\(fileName).\(TemplateConstants.ScriptExtension)"

            let scriptFilePath = loadPath / scriptFileName

            if !scriptFilePath.exists { continue } //check if found in next oath

            let file = LocalFile(path: scriptFilePath )

            if let script = LocalScriptFile(file: file) {
                self.scriptFileCache[fileName] = script
                return script
            } else {
                throw TemplateSoup_EvaluationError.scriptFileReadingError(fileName, pInfo)
            }
        }

        throw TemplateSoup_EvaluationError.scriptFileDoesNotExist(fileName, pInfo)
    }
    
    public func loadTemplate(fileName: String, with pInfo: ParsedInfo) throws -> Template {
        for loadPath in paths {
            if !loadPath.exists {
                let pInfo = ParsedInfo.dummyForAppState(with: context)
                throw EvaluationError.invalidAppState("Blueprint folder '\(loadPath.string)' not found!!!", pInfo)
            }
            
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
    
    private func loadPathExists() -> Bool {
        return rootPath.exists
    }
    
    public func blueprintExists() throws -> Bool {
        if !loadPathExists() {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidAppState("Blueprint root folder '\(rootPath.string)'not found!!!", pInfo)
        }
        
        return self.blueprintPath.exists
    }
    
    public func hasFolder(_ foldername: String) -> Bool {
        guard self.blueprintPath.exists else {
            return false
        }
        
        let inFolder = LocalFolder(path: self.blueprintPath / foldername)
        return inFolder.path.exists
    }
    
    public func copyFiles(foldername: String, to outputFolder: LocalFolder, with pInfo: ParsedInfo) throws {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.blueprintPath.string)", pInfo)
        }
        
        do {
            let inFolder = LocalFolder(path: self.blueprintPath / foldername)
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
    
    public func renderFiles(foldername: String, to outputFolder: LocalFolder, using templateSoup: TemplateSoup, with pInfo: ParsedInfo) throws {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.blueprintPath.string)", pInfo)
        }
        
        do {
            let inFolder = LocalFolder(path: self.blueprintPath / foldername)
            
            try renderLocalFiles(from: inFolder, to: outputFolder, using: templateSoup, with: pInfo)
        } catch let err {
            if let _ = err as? ErrorWithMessageAndParsedInfo {
                throw err
            } else {
                let message = "Could not render files from \(foldername) to \(outputFolder.path.string)"
                throw EvaluationError.failedWriteOperation(message, pInfo)
            }
        }
    }
    
    private func renderLocalFiles(from inFolder: LocalFolder, to outputFolder: LocalFolder, using templateSoup: TemplateSoup, with pInfo: ParsedInfo) throws {
                
        let files = inFolder.files
        
        for file in files {
            if file.extension == TemplateConstants.TemplateExtension { //template file
                let actualFilename = file.nameExcludingExtension
                
                //render the filename if it has an expression within '{{' and '}}'
                let filename = try ContentHandler.eval(expression: actualFilename, with: templateSoup.context) ?? actualFilename
                
                //if handler returns false, dont render file
                if try !context.events.canRender(filename: filename, with: pInfo) {
                    continue
                }
                
                let contents = try file.readTextContents()
                
                let renderClosure = { outputname, pInfo in
                    if let renderedString = try templateSoup.renderTemplate(string: contents, identifier: actualFilename, with: pInfo) {
                        
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
                    try templateSoup.forEach(forInExpression: pInfo.line, with: pInfo) {
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
            try renderLocalFiles(from: subFolder, to: newFolder, using: templateSoup, with: pInfo)
        }
        
    }
    
    public func readTextContents(filename: String, with pInfo: ParsedInfo) throws -> String {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput("There is no folder called \(self.blueprintPath.string)", pInfo)
        }
        
        let inFile = LocalFile(path: self.blueprintPath / filename)
        let inFileContents = try inFile.readTextContents()
        return inFileContents
    }
    
    public func add(paths: LocalPath...) {
        self.paths.append(contentsOf: paths)
    }
    
    public func add(paths: [LocalPath]) {
        self.paths.append(contentsOf: paths)
    }
    
    public init(blueprint: String, path templatesPath: LocalPath, with ctx: GenerationContext) {
        let path = templatesPath / blueprint

        self.paths = [path]
        self.context = ctx
        self.blueprintPath = path
        self.blueprintName = blueprint
        self.rootPath = templatesPath
    }
    
    internal init(path: LocalPath, with ctx: GenerationContext) {
        self.paths = [path]
        self.context = ctx
        self.blueprintPath = path
        self.rootPath = path
        self.blueprintName = ""
    }
}

