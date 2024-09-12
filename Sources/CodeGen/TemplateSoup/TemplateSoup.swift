//
// TemplateSoup.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias LoadTemplateHandler = (_ templateName: String,_ loader: BlueprintRepository, _ ctx: Context) throws -> Template

public class TemplateSoup : TemplateRenderer {
    var templateEval: TemplateEvaluator
    let context: Context
    var repo: BlueprintRepository
    
    var onLoadTemplate : LoadTemplateHandler = { (templateName, loader, ctx) throws -> Template in
        do {
            return try loader.loadTemplate(fileName: templateName)
        } catch {
          throw TemplateDoesNotExist(templateName: templateName)
        }
    }
    
    public func loadTemplate(fileName: String) throws -> Template {
        return try onLoadTemplate(fileName, repo, context)
    }
    
    //MARK: TemplateRenderer protocol implementation
    public func renderTemplateWithFrontMatter(fileName templateFile: String) throws -> String? {
        var templateString = ""
        
        guard let fileTemplate = try self.loadTemplate(fileName: templateFile) as? TemplateSoupTemplate else { return nil }
        
        let content = fileTemplate.toString()
        let lineParser = LineParser(string: content, with: context)
        
        let curLine = lineParser.currentLine()
            
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            try FrontMatter (lineParser: lineParser, with: context)
            templateString = lineParser.getRemainingLinesAsString()
        } else {
            templateString = lineParser.getRemainingLinesAsString()
        }
        
        context.pushSnapshot()
        
        let template: StringTemplate = "\(templateString)"
        let rendering = try templateEval.execute(template: template, context: context)
        
        context.popSnapshot()
        
        return rendering
    }
    
    public func renderTemplateWithoutFrontMatter(fileName: String, data: StringDictionary = [:]) throws -> String? {
        context.pushSnapshot()
        context.append(variables: data)
        
        let template = try loadTemplate(fileName: fileName)        
        let rendering =  try templateEval.execute(template: template, context: context)
        
        context.popSnapshot()
        
        //print(rendering)
        return rendering
    }
    
    public func renderTemplate(string templateString: String, data: StringDictionary = [:]) throws -> String? {
        context.pushSnapshot()
        context.append(variables: data)
        
        let template: StringTemplate = "\(templateString)"
        let rendering = try templateEval.execute(template: template, context: context)
        
        context.popSnapshot()
        
        //print(rendering)
        return rendering
    }
    
    public init(loader: BlueprintRepository, context: Context) {
        self.repo = loader

        self.templateEval = TemplateEvaluator()
        self.context = context
    }

    public init(context: Context) {
        let fsLoader = LocalFileBlueprintLoader(path: context.paths.basePath, with: context)
        self.repo = fsLoader

        self.templateEval = TemplateEvaluator()
        self.context = context
    }
}

public protocol TemplateRenderer {
    func renderTemplateWithFrontMatter(fileName templateFile: String) throws -> String?
    func renderTemplateWithoutFrontMatter(fileName: String, data: StringDictionary) throws -> String?
    func renderTemplate(string templateString: String, data: StringDictionary) throws -> String?
}
