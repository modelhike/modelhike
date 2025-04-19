//
//  TemplateEvaluator.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct TemplateEvaluator: TemplateSoupEvaluator {

    public func execute(template: Template, with context: GenerationContext) async throws -> String? {
        let contents = template.toString()
        let lineparser = LineParserDuringGeneration(
            string: contents, identifier: template.name, isStatementsPrefixedWithKeyword: true,
            with: context)

        return try await execute(lineParser: lineparser, with: context)
    }

    public func execute(lineParser: LineParserDuringGeneration, with ctx: GenerationContext) async throws
        -> String?
    {

        let parser = TemplateSoupParser(lineParser: lineParser, context: ctx)

        do {
            await ctx.debugLog.templateParsingStarting()
            try await ctx.events.onBeforeParseTemplate?(lineParser.identifier, ctx)

            let curLine = await lineParser.currentLine()

            if curLine.hasOnly(TemplateConstants.frontMatterIndicator) {
                var frontMatter = try await FrontMatter(lineParser: lineParser, with: ctx)
                try await frontMatter.processVariables()
            }

            if let containers = try await parser.parseContainers() {
                await ctx.debugLog.printParsedTree(for: containers)

                await ctx.debugLog.templateExecutionStarting()
                try await ctx.events.onBeforeExecuteTemplate?(lineParser.identifier, ctx)

                if let body = try await containers.execute(with: ctx) {
                    return body
                }
            }
        } catch let err {
            if let parseErr = err as? TemplateSoup_ParsingError {
                throw ParsingError.invalidLine(parseErr.pInfo, parseErr)
            } else if let evalErr = err as? TemplateSoup_EvaluationError {
                if case let .workingDirectoryNotSet(pInfo) = evalErr {
                    throw EvaluationError.workingDirectoryNotSet(pInfo, evalErr)
                } else if case let .unIdentifiedStmt(pInfo) = evalErr {
                    throw EvaluationError.invalidLine(pInfo, evalErr)
                } else {
                    throw EvaluationError.invalidLine(evalErr.pInfo, evalErr)
                }
            } else if let directive = err as? ParserDirective {
                if case let .excludeFile(filename) = directive {
                    await ctx.debugLog.excludingFile(filename)
                    return nil  //nothing to generate from this excluded file
                } else if case let .stopRenderingCurrentFile(filename, pInfo) = directive {
                    await ctx.debugLog.stopRenderingCurrentFile(filename, pInfo: pInfo)
                    return nil  //nothing to generate from this rendering stopped file
                } else if case let .throwErrorFromCurrentFile(filename, errMsg, pInfo) = directive {
                    await ctx.debugLog.throwErrorFromCurrentFile(filename, err: errMsg, pInfo: pInfo)
                    throw EvaluationError.templateRenderingError(pInfo, directive)
                }
            } else {
                throw err
            }
        }

        return nil
    }

}

public protocol TemplateSoupEvaluator {
    func execute(template: Template, with ctx: GenerationContext) async throws -> String?
}
