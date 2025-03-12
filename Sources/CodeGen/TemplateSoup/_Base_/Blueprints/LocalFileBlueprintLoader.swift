//
//  LocalFileBlueprintLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class LocalFileBlueprintLoader: Blueprint {
    private var templateCache: [String: Template] = [:]
    private var scriptFileCache: [String: Script] = [:]

    public let blueprintPath: LocalPath
    public let rootPath: LocalPath
    public let context: GenerationContext
    public var paths: [LocalPath]
    public let blueprintName: String

    public func loadScriptFile(fileName: String, with pInfo: ParsedInfo) throws -> any Script {
        for loadPath in paths {
            if !loadPath.exists {
                let pInfo = ParsedInfo.dummyForAppState(with: context)
                throw EvaluationError.invalidAppState(
                    "Blueprint folder '\(loadPath.string)' not found!!!", pInfo)
            }

            let scriptFileName = "\(fileName).\(TemplateConstants.ScriptExtension)"

            let scriptFilePath = loadPath / scriptFileName

            if !scriptFilePath.exists { continue }  //check if found in next oath

            let file = LocalFile(path: scriptFilePath)

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
                throw EvaluationError.invalidAppState(
                    "Blueprint folder '\(loadPath.string)' not found!!!", pInfo)
            }

            let templateName = "\(fileName).\(TemplateConstants.TemplateExtension)"

            let templatePath = loadPath / templateName

            if !templatePath.exists { continue }  //check if found in next oath

            let file = LocalFile(path: templatePath)

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
            throw EvaluationError.invalidAppState(
                "Blueprint root folder '\(rootPath.string)'not found!!!", pInfo)
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

    public func copyFiles(foldername: String, to outputFolder: OutputFolder, with pInfo: ParsedInfo)
        throws
    {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput(
                "There is no folder called \(self.blueprintPath.string)", pInfo)
        }

        do {
            let inFolder = LocalFolder(path: self.blueprintPath / foldername)
            
            for file in inFolder.files {
                let copyFile = FileToCopy(file: file, pInfo: pInfo)
                outputFolder.add(copyFile)
            }
            
            //copy files from subfolders also
            for subFolder in inFolder.subFolders {
                let outputSubFolder = outputFolder.subFolder(subFolder.name)
                try copyFiles(foldername: subFolder.name, to: outputSubFolder, with: pInfo)
            }
            
        } catch let err {
            if err as? ErrorWithMessageAndParsedInfo != nil {
                throw err
            } else {
                let message =
                    "Could not copy files from \(foldername) to \(outputFolder.path.string)"
                throw EvaluationError.failedWriteOperation(message, pInfo)
            }
        }
    }

    public func renderFiles(
        foldername: String, to outputFolder: OutputFolder, using templateSoup: TemplateSoup,
        with pInfo: ParsedInfo
    ) throws {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput(
                "There is no folder called \(self.blueprintPath.string)", pInfo)
        }

        do {
            let inFolder = LocalFolder(path: self.blueprintPath / foldername)

            try renderLocalFiles(from: inFolder, to: outputFolder, using: templateSoup, with: pInfo)
        } catch let err {
            if err as? ErrorWithMessageAndParsedInfo != nil {
                throw err
            } else {
                let message =
                    "Could not render files from \(foldername) to \(outputFolder.path.string)"
                throw EvaluationError.failedWriteOperation(message, pInfo)
            }
        }
    }

    private func renderLocalFiles(
        from inFolder: LocalFolder, to outputFolder: OutputFolder, using templateSoup: TemplateSoup,
        with pInfo: ParsedInfo
    ) throws {

        let files = inFolder.files

        for file in files {
            if file.extension == TemplateConstants.TemplateExtension {  //template file
                let actualTemplateFilename = file.nameExcludingExtension

                //render the filename if it has an expression within '{{' and '}}'
                let filename =
                    try ContentHandler.eval(expression: actualTemplateFilename, with: templateSoup.context)
                    ?? actualTemplateFilename

                let contents = try file.readTextContents()

                let renderClosure = { [self] (outputname: String, pInfo: ParsedInfo) in
                    do{
                    let outputFilename: String = outputname.isNotEmpty ? outputname : filename

                    //if handler returns false, dont render file
                    if try !self.context.events.canRender(filename: outputFilename, templatename: actualTemplateFilename, with: pInfo) {
                        return
                    }
                    
                    //check if parser directives to exclude file
                    if let ctx = pInfo.ctx as? GenerationContext {
                        if let frontMatter = try FrontMatter(in: contents, filename: filename, with: ctx) {
                            try frontMatter.processVariables()
                        }
                    }
                    
                    if let renderedString = try templateSoup.renderTemplate(
                        string: contents, identifier: actualTemplateFilename, with: pInfo)
                    {
                        
                        templateSoup.context.debugLog.generatingFileInFolder(
                            filename, with: actualTemplateFilename, folder: outputFolder.folder)

                        let outFile = RenderedFile(filename: outputFilename, contents: renderedString, pInfo: pInfo )
                        outputFolder.add(outFile)
                    }
                    } catch let err {
                        if let directive = err as? ParserDirective {
                            if case let .excludeFile(filename) = directive {
                                pInfo.ctx.debugLog.excludingFile(filename)
                                return  //nothing to generate from this excluded file
                            } else if case let .stopRenderingCurrentFile(filename, pInfo) = directive {
                                pInfo.ctx.debugLog.stopRenderingCurrentFile(filename, pInfo: pInfo)
                                return  //nothing to generate from this rendering stopped file
                            } else if case let .throwErrorFromCurrentFile(filename, errMsg, pInfo) = directive {
                                pInfo.ctx.debugLog.throwErrorFromCurrentFile(filename, err: errMsg, pInfo: pInfo)
                                throw EvaluationError.templateRenderingError(pInfo, directive)
                            }
                        } else {
                            throw err
                        }
                    }
                }

                let parsingIdentifier = actualTemplateFilename
                if let frontMatter = try templateSoup.frontMatter(
                    in: contents, identifier: parsingIdentifier),
                    let pInfo = frontMatter.hasDirective(ParserDirective.includeFor)
                {
                    try templateSoup.forEach(forInExpression: pInfo.line, with: pInfo) {
                        if frontMatter.hasDirective(ParserDirective.outputFilename) != nil {
                            if let outputFilename = try frontMatter.evalDirective(
                                ParserDirective.outputFilename, pInfo: pInfo) as? String
                            {
                                try renderClosure(outputFilename, pInfo)
                            }
                        } else {
                            try renderClosure("", pInfo)
                        }
                    }
                } else {
                    let pInfo = ParsedInfo.dummyForFrontMatterError(
                        identifier: parsingIdentifier, with: context)
                    try renderClosure("", pInfo)
                }

            } else {  //not a template file
                //create the folder only if any file is copied
                try outputFolder.ensureExists()

                templateSoup.context.debugLog.copyingFileInFolder(file.name, folder: outputFolder.folder)

                let copyFile = FileToCopy(file: file, pInfo: pInfo)
                outputFolder.add(copyFile)
            }
        }

        //copy files from subfolders also
        for subFolder in inFolder.subFolders {
            let subfoldername =
                try ContentHandler.eval(expression: subFolder.name, with: templateSoup.context)
                ?? subFolder.name

            let newFolder = outputFolder.subFolder(subfoldername)
            try renderLocalFiles(from: subFolder, to: newFolder, using: templateSoup, with: pInfo)
        }

    }

    public func readTextContents(filename: String, with pInfo: ParsedInfo) throws -> String {
        guard self.blueprintPath.exists else {
            throw EvaluationError.invalidInput(
                "There is no folder called \(self.blueprintPath.string)", pInfo)
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
