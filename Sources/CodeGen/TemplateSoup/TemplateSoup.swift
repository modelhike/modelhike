//
// TemplateSoup.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias LoadTemplateHandler = (_ templateName: String,_ loader: BlueprintRepository, _ ctx: Context) throws -> Template

public class TemplateSoup : TemplateRenderer {
    let context: Context
    var repo: BlueprintRepository
    
    var onLoadTemplate : LoadTemplateHandler = { (templateName, loader, ctx) throws -> Template in
        do {
            return try loader.loadTemplate(fileName: templateName)
        } catch {
            throw TemplateSoup_EvaluationError.templateDoesNotExist(templateName)
        }
    }
    
    public func loadTemplate(fileName: String) throws -> Template {
        return try onLoadTemplate(fileName, repo, context)
    }
    
    //MARK: TemplateRenderer protocol implementation
    public func renderTemplate(fileName templateFile: String, data: StringDictionary = [:]) throws -> String? {
        do {
            
            let fileTemplate = try self.loadTemplate(fileName: templateFile)
            
            let content = fileTemplate.toString()
            let lineParser = LineParser(string: content, with: context)
            
            let curLine = lineParser.currentLine()
            
            if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
                try FrontMatter (lineParser: lineParser, with: context)
            }
            
            context.pushSnapshot()
            context.append(variables: data)
            
            let templateEval = TemplateEvaluator()
            let rendering = try templateEval.execute(identifier: templateFile, lineparser: lineParser, with: context)
            
            context.popSnapshot()
            
            return rendering
        } catch let err {
            if let evalErr = err as? TemplateSoup_EvaluationError {
                let lineNo = 0 //parser.lineParser.curLineNoForDisplay
                let identifier = templateFile
                if case .templateDoesNotExist(_) = evalErr {
                    throw EvaluationError.templateDoesNotExist(lineNo, identifier, evalErr.info)
                } else if case .templateReadingError(_) = evalErr {
                    throw EvaluationError.readingError(lineNo, identifier, evalErr.info)
                }
            }
            
            throw err
        }
    }
    
    public func renderTemplate(string templateString: String, identifier: String = "", data: StringDictionary = [:]) throws -> String? {
        context.pushSnapshot()
        context.append(variables: data)
        
        let template = StringTemplate(contents: templateString, name: identifier)

        let templateEval = TemplateEvaluator()
        let rendering = try templateEval.execute(template: template, context: context)
        
        context.popSnapshot()
        
        //print(rendering)
        return rendering
    }
    
    public init(loader: BlueprintRepository, context: Context) {
        self.repo = loader
        self.context = context
    }

    public init(context: Context) {
        let fsLoader = LocalFileBlueprintLoader(path: context.paths.basePath, with: context)
        self.repo = fsLoader
        self.context = context
    }
}

public protocol TemplateRenderer {
    func renderTemplate(fileName templateFile: String, data: StringDictionary) throws -> String?
    func renderTemplate(string templateString: String, identifier: String, data: StringDictionary) throws -> String?
}
