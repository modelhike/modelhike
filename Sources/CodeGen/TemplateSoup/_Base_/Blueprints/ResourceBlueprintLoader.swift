//
//  ResourceBlueprintLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class ResourceBlueprintLoader: Blueprint {
    private var templateCache: [String: Template] = [:]
    private var scriptFileCache: [String: Script] = [:]

    public let context: GenerationContext

    public let blueprintName: String
    let bundle: Bundle
    public var blueprintPath: String
    public var resourceRoot: String

    public func loadScriptFile(fileName: String, with pInfo: ParsedInfo) throws -> any Script {
        if let resourceURL = bundle.url(
            forResource: fileName,
            withExtension: TemplateConstants.ScriptExtension,
            subdirectory: blueprintPath)
        {
            do {
                let content = try String(contentsOf: resourceURL)
                let template = StringTemplate(contents: content, name: fileName)
                self.scriptFileCache[fileName] = template
                return template
            } catch {
                throw TemplateSoup_EvaluationError.scriptFileReadingError(fileName, pInfo)
            }
        } else {
            throw TemplateSoup_EvaluationError.scriptFileDoesNotExist(fileName, pInfo)
        }

    }

    public func loadTemplate(fileName: String, with pInfo: ParsedInfo) throws -> Template {
        if let resourceURL = bundle.url(
            forResource: fileName,
            withExtension: TemplateConstants.TemplateExtension,
            subdirectory: blueprintPath)
        {
            do {
                let content = try String(contentsOf: resourceURL)
                let template = StringTemplate(contents: content, name: fileName)
                self.templateCache[fileName] = template
                return template
            } catch {
                throw TemplateSoup_EvaluationError.templateReadingError(fileName, pInfo)
            }
        } else {
            throw TemplateSoup_EvaluationError.templateDoesNotExist(fileName, pInfo)
        }

    }

    private func loadPathExists() -> Bool {
        do {
            let folder = blueprintPath
            guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else {
                return false
            }

            let fm = FileManager.default
            let resourcePaths = try fm.contentsOfDirectory(
                at: resourceURL, includingPropertiesForKeys: nil)

            return resourcePaths.count > 0
        } catch {
            return false
        }
    }

    public func blueprintExists() throws -> Bool {
        if !loadPathExists() {
            let pInfo = ParsedInfo.dummyForAppState(with: context)
            throw EvaluationError.invalidAppState(
                "Blueprint resource root folder not found!!!", pInfo)
        }

        return hasFolder("")  //check blueprint path
    }

    public func hasFolder(_ foldername: String) -> Bool {
        do {
            let folder = blueprintPath + foldername
            guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else {
                return false
            }

            let fm = FileManager.default
            let resourcePaths = try fm.contentsOfDirectory(
                at: resourceURL, includingPropertiesForKeys: nil)

            return resourcePaths.count > 0
        } catch {
            return false
        }
    }

    public func copyFiles(foldername: String, to outputFolder: LocalFolder, with pInfo: ParsedInfo)
        throws
    {
        let folder = blueprintPath + foldername
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return }

        try copyResourceFiles(from: resourceURL, to: outputFolder.path, pInfo: pInfo)
    }

    fileprivate func copyResourceFiles(
        from resUrl: URL, to outputPath: LocalPath, pInfo: ParsedInfo
    ) throws {
        let fm = FileManager.default
        try outputPath.ensureExists()

        do {
            let resourcePaths = try fm.contentsOfDirectory(
                at: resUrl, includingPropertiesForKeys: nil)
            for resourcePath in resourcePaths {
                let resourceName = resourcePath.lastPathComponent

                if !resourcePath.hasDirectoryPath {  //resource file
                    let contents = try String(contentsOf: resourcePath)

                    let filename = resourceName
                    let outFile = LocalFile(path: outputPath / filename)
                    try outFile.write(contents)
                } else {  //resource folder
                    let newResUrl = resUrl.appendingPathComponent(resourceName)
                    try copyResourceFiles(
                        from: newResUrl, to: outputPath / resourceName, pInfo: pInfo)
                }
            }
        } catch {
            print(error)
            throw ResourceDoesNotExist(resName: resUrl.absoluteString, pInfo: pInfo)
        }
    }

    public func renderFiles(
        foldername: String, to outputFolder: LocalFolder, using templateSoup: TemplateSoup,
        with pInfo: ParsedInfo
    ) throws {
        let folder = blueprintPath + foldername
        guard let resourceURL = bundle.resourceURL?.appendingPathComponent(folder) else { return }

        try renderResourceFiles(
            from: resourceURL, to: outputFolder, using: templateSoup, with: pInfo)
    }

    fileprivate func renderResourceFiles(
        from resUrl: URL, to outputFolder: LocalFolder, using templateSoup: TemplateSoup,
        with pInfo: ParsedInfo
    ) throws {
        let fm = FileManager.default

        do {
            let resourcePaths = try fm.contentsOfDirectory(
                at: resUrl, includingPropertiesForKeys: nil)
            for resourcePath in resourcePaths {
                var resourceName = resourcePath.lastPathComponent

                if !resourcePath.hasDirectoryPath {  //resource file
                    if resourceName.fileExtension() == TemplateConstants.TemplateExtension {  //if tempalte file

                        resourceName = resourceName.withoutFileExtension()

                        //render the filename if it has an expression within '{{' and '}}'
                        let filename =
                            try ContentHandler.eval(
                                expression: resourceName, with: templateSoup.context)
                            ?? resourceName

                        //if handler returns false, dont render file
                        if try !context.events.canRender(filename: filename, with: pInfo) {
                            continue
                        }

                        let contents = try String(contentsOf: resourcePath)

                        let renderClosure = { outputname, pInfo in
                            if let renderedString = try templateSoup.renderTemplate(
                                string: contents, identifier: resourceName, with: pInfo)
                            {

                                //create the folder only if any file is rendered
                                try outputFolder.ensureExists()

                                templateSoup.context.debugLog.generatingFileInFolder(
                                    filename, with: resourceName, folder: outputFolder)

                                let ouputFilename: String =
                                    outputname.isNotEmpty ? outputname : filename
                                let outFile = LocalFile(path: outputFolder.path / ouputFilename)
                                try outFile.write(renderedString)
                            }
                        }

                        let parsingIdentifier = resourceName
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

                        let contents = try Data(contentsOf: resourcePath)
                        let filename = resourceName

                        templateSoup.context.debugLog.copyingFileInFolder(
                            filename, folder: outputFolder)

                        let outFile = LocalFile(path: outputFolder.path / filename)
                        try outFile.write(contents)
                    }
                } else {  //resource folder
                    let subfoldername =
                        try ContentHandler.eval(
                            expression: resourceName, with: templateSoup.context) ?? resourceName

                    let newResUrl = resUrl.appendingPathComponent(subfoldername)
                    try renderResourceFiles(
                        from: newResUrl, to: outputFolder / resourceName, using: templateSoup,
                        with: pInfo)
                }
            }
        } catch {
            print(error)
            throw ResourceDoesNotExist(resName: resUrl.absoluteString, pInfo: pInfo)
        }
    }

    public func readTextContents(filename: String, with pInfo: ParsedInfo) throws -> String {
        if let resourceURL = bundle.url(
            forResource: filename,
            withExtension: TemplateConstants.TemplateExtension,
            subdirectory: blueprintPath)
        {
            do {
                let content = try String(contentsOf: resourceURL)
                return content
            } catch {
                throw ResourceReadingError(resName: filename, pInfo: pInfo)
            }
        } else {
            throw ResourceDoesNotExist(resName: filename, pInfo: pInfo)
        }
    }

    public init(
        blueprint: String, blueprintsRoot: String, resourceRoot: String, bundle: Bundle,
        with ctx: GenerationContext
    ) {
        self.bundle = bundle
        self.blueprintName = blueprint
        self.blueprintPath = "\(blueprintsRoot)\(blueprint)/"
        self.resourceRoot = resourceRoot
        self.context = ctx
    }

}

public struct ResourceReadingError: ErrorWithMessageAndParsedInfo {
    let resName: String
    public let pInfo: ParsedInfo

    public var info: String {
        return "Resource \(resName) reading error."
    }

    public init(resName: String, pInfo: ParsedInfo) {
        self.resName = resName
        self.pInfo = pInfo
    }
}

public struct ResourceDoesNotExist: ErrorWithMessageAndParsedInfo {
    let resName: String
    public let pInfo: ParsedInfo

    public var info: String {
        return "Resource \(resName) does not exist."
    }

    public init(resName: String, pInfo: ParsedInfo) {
        self.resName = resName
        self.pInfo = pInfo
    }
}
