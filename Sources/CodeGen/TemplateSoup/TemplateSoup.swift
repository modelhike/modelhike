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
    
    public var onLoadTemplate : LoadTemplateHandler = { (templateName, loader, ctx) throws -> Template in
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
            
            context.pushSnapshot()
            context.append(variables: data)
            
            let templateEval = TemplateEvaluator()
            let rendering = try templateEval.execute(template: fileTemplate, with: context)
            
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
        
        let template = StringTemplate(contents: templateString, name: identifier)

        context.pushSnapshot()
        context.append(variables: data)
        
        let templateEval = TemplateEvaluator()
        let rendering = try templateEval.execute(template: template, with: context)
        
        context.popSnapshot()
        
        //print(rendering)
        return rendering
    }
    
    public func forEach(forInExpression expression: String, parser: LineParser, renderClosure: () throws -> Void ) throws {
        let line = "\(ForStmt.START_KEYWORD) \(expression)"
        guard let match = line.wholeMatch(of: ForStmt.stmtRegex ) else {
            throw ParsingError.invalidLineWithoutErr(parser.curLineNoForDisplay, parser.identifier, expression)
        }
        
        let (_, forVar, inArrayVar) = match.output
        let loopVariableName = forVar
        
        guard let loopItems = try context.valueOf(variableOrObjProp: inArrayVar, lineNo: parser.curLineNoForDisplay) as? [Any] else {
            throw ParsingError.invalidLineWithoutErr(parser.curLineNoForDisplay, parser.identifier, expression)
        }
        
        context.pushSnapshot()
        
        for (index, loopItem) in loopItems.enumerated() {
            context.variables[loopVariableName] = loopItem
            
            context.variables[ForStmt.FIRST_IN_LOOP] = index == loopItems.startIndex
            context.variables[ForStmt.LAST_IN_LOOP] = index == loopItems.index(before: loopItems.endIndex)
            
            try renderClosure()
        }
        
        context.popSnapshot()
    }
    
    public func frontMatter(in contents: String, identifier: String) throws -> FrontMatter? {
        let lineParser = LineParser(string: contents, identifier: identifier, with: context)
        let curLine = lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            let frontMatter = try FrontMatter (lineParser: lineParser, with: context)
            return frontMatter
        }
        
        return nil
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
