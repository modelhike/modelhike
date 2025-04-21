//
//  TemplateSoup.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public typealias LoadTemplateHandler = @Sendable (_ templateName: String,_ loader: Blueprint, _ pInfo: ParsedInfo) async throws -> Template
public typealias LoadScriptHandler = @Sendable (_ scriptName: String,_ loader: Blueprint, _ pInfo: ParsedInfo) async throws -> Script

public actor TemplateSoup : TemplateRenderer {
    let context: GenerationContext
    var blueprint: Blueprint
    
    public func blueprint(_ value: Blueprint) {
        self.blueprint = value
    }
    
    public var onLoadTemplate : LoadTemplateHandler = { (templateName, loader, pInfo) async throws -> Template in
        do {
            return try await loader.loadTemplate(fileName: templateName, with: pInfo)
        } catch {
            throw TemplateSoup_EvaluationError.templateDoesNotExist(templateName, pInfo)
        }
    }
    
    public var onLoadScript : LoadScriptHandler = { (scriptName, loader, pInfo) async throws -> Script in
        do {
            return try await loader.loadScriptFile(fileName: scriptName, with: pInfo)
        } catch {
            throw TemplateSoup_EvaluationError.scriptFileDoesNotExist(scriptName, pInfo)
        }
    }
    
    public func onLoadTemplate(_ newValue: @escaping LoadTemplateHandler) {
        self.onLoadTemplate = newValue
    }
    
    public func loadScript(fileName: String, with pInfo: ParsedInfo) async throws -> Script {
        return try await onLoadScript(fileName, blueprint, pInfo)
    }
    
    public func loadTemplate(fileName: String, with pInfo: ParsedInfo) async throws -> Template {
        return try await onLoadTemplate(fileName, blueprint, pInfo)
    }
    
    public func startMainScript(data: StringDictionary = [:], with pInfo: ParsedInfo) async throws -> String? {
        let filename = TemplateConstants.MainScriptFile
        return try await runScript(fileName: filename, data: data, with: pInfo)
    }
    
    public func runScript(fileName scriptFile: String, data: StringDictionary = [:], with pInfo: ParsedInfo) async throws -> String? {
        do {
            let fileScript = try await self.loadScript(fileName: scriptFile, with: pInfo)
            
            await context.pushSnapshot()
            await context.append(variables: data)
            
            let scriptEval = ScriptFileExecutor()
            let rendering = try await scriptEval.execute(script: fileScript, with: context)
            
            await context.popSnapshot()
            
            return rendering
        } catch let err {
            if let parseErr = err as? TemplateSoup_ParsingError {
                throw ParsingError.invalidLine(parseErr.pInfo, parseErr)
            } else if let evalErr = err as? TemplateSoup_EvaluationError {
                if case .scriptFileDoesNotExist(_, pInfo) = evalErr {
                    throw EvaluationError.scriptFileDoesNotExist(pInfo, evalErr)
                } else if case .scriptFileReadingError(_, pInfo) = evalErr {
                    throw EvaluationError.readingError(pInfo, evalErr)
                    
                } else if case let .workingDirectoryNotSet(pInfo) = evalErr {
                        throw EvaluationError.workingDirectoryNotSet(pInfo, evalErr)
                } else if case let .unIdentifiedStmt(pInfo) = evalErr {
                    throw EvaluationError.invalidLine(pInfo, evalErr)
                } else {
                    throw EvaluationError.invalidLine(evalErr.pInfo, evalErr)
                }
            } else if let directive = err as? ParserDirective {
                if case let .excludeFile(filename) = directive {
                    context.debugLog.excludingFile(filename)
                    return nil  //nothing to generate from this excluded file
                } else if case let .stopRenderingCurrentFile(filename, pInfo) = directive {
                    context.debugLog.stopRenderingCurrentFile(filename, pInfo: pInfo)
                    return nil  //nothing to generate from this rendering stopped file
                } else if case let .throwErrorFromCurrentFile(filename, errMsg, pInfo) = directive {
                    context.debugLog.throwErrorFromCurrentFile(filename, err: errMsg, pInfo: pInfo)
                    throw EvaluationError.templateRenderingError(pInfo, directive)
                }
            } else {
                throw err
            }
            
            return nil
        }
    }
    
    //MARK: TemplateRenderer protocol implementation
    public func renderTemplate(fileName templateFile: String, data: StringDictionary = [:], with pInfo: ParsedInfo) async throws -> String? {
        do {
            
            let fileTemplate = try await self.loadTemplate(fileName: templateFile, with: pInfo)
            
            await context.pushSnapshot()
            await context.append(variables: data)
            
            let templateEval = TemplateEvaluator()
            let rendering = try await templateEval.execute(template: fileTemplate, with: context)
            
            await context.popSnapshot()
            
            return rendering
        } catch let err {
            if let evalErr = err as? TemplateSoup_EvaluationError {
                if case .templateDoesNotExist(_, pInfo) = evalErr {
                    throw EvaluationError.templateDoesNotExist(pInfo, evalErr)
                } else if case .templateReadingError(_, pInfo) = evalErr {
                    throw EvaluationError.readingError(pInfo, evalErr)
                }
            }
            
            throw err
        }
    }
    
    public func renderTemplate(string templateString: String, identifier: String = "", data: StringDictionary = [:], with pInfo: ParsedInfo) async throws -> String? {
        
        let template = StringTemplate(contents: templateString, name: identifier)

        await context.pushSnapshot()
        await context.append(variables: data)
        
        let templateEval = TemplateEvaluator()
        let rendering = try await templateEval.execute(template: template, with: context)
        
        await context.popSnapshot()
        
        //print(rendering)
        return rendering
    }
    
    public func forEach(forInExpression expression: String, with pInfo: ParsedInfo, renderClosure: @Sendable () async throws -> Void ) async throws {
        let line = "\(ForStmt.START_KEYWORD) \(expression)"
                                                  
        guard let match = line.wholeMatch(of: ForStmt.stmtRegex ) else {
            throw ParsingError.invalidLineWithoutErr(expression, pInfo)
        }
        
        let (_, forVar, inArrayVar) = match.output
        let loopVariableName = forVar
        
        guard let loopItems = try await context.valueOf(variableOrObjProp: inArrayVar, with: pInfo) as? [Sendable] else {
            throw ParsingError.invalidLineWithoutErr(expression, pInfo)
        }
        
        await context.pushSnapshot()
        //dummy for-stmt instantiated
        let loopWrap = ForLoop_Wrap(ForStmt(parseTill: "", pInfo: pInfo))
        await context.variables.set(ForStmt.LOOP_VARIABLE, value: loopWrap)
        
        for (index, loopItem) in loopItems.enumerated() {
            await context.variables.set(loopVariableName, value: loopItem)
            
            await loopWrap.FIRST_IN_LOOP( index == loopItems.startIndex )
            await loopWrap.LAST_IN_LOOP( index == loopItems.index(before: loopItems.endIndex))
            
            try await renderClosure()
        }
        
        await context.popSnapshot()
    }
    
    public func frontMatter(in contents: String, identifier: String) async throws -> FrontMatter? {
        let lineParser = LineParserDuringGeneration(string: contents, identifier: identifier, isStatementsPrefixedWithKeyword: true, with: context)
        let curLine = await lineParser.currentLine()
        
        if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
            let frontMatter = try await FrontMatter (lineParser: lineParser, with: context)
            return frontMatter
        }
        
        return nil
    }
        
    public init(loader: Blueprint, context: GenerationContext) {
        self.blueprint = loader
        self.context = context
    }

    public init(context: GenerationContext) async {
        let path = await context.config.basePath
        let fsLoader = LocalFileBlueprintLoader(path: path, with: context)
        self.blueprint = fsLoader
        self.context = context
    }
}

public protocol TemplateRenderer: Sendable {
    func renderTemplate(fileName templateFile: String, data: StringDictionary, with pInfo: ParsedInfo) async throws -> String?
    func renderTemplate(string templateString: String, identifier: String, data: StringDictionary, with pInfo: ParsedInfo) async throws -> String?
}
