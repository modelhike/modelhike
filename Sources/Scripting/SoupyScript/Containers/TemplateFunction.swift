//
//  TemplateFunctionContainer.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor TemplateFunction: SoupyScriptStmtContainer {
    let container: GenericStmtsContainer

    let params: [String]
    let name: String
    let pInfo: ParsedInfo

    public func execute(args: [ArgumentDeclaration], pInfo: ParsedInfo, with ctx: Context) async throws
        -> String?
    {
        var rendering = ""

        //IMPORTANT : ctx push/pop should not be used here as
        //any variable modification
        //that is done inside the template fn body should be persisted
        //only the template fn args are to be removed after execution
        //so, the template fn args are removed manually

        //ctx.pushSnapshot()

        //backup any variables clashing with the arguments
        var oldArgValues: StringDictionary = [:]
        for arg in args {
            if await ctx.variables.has(arg.name) {
                oldArgValues[arg.name] = await ctx.variables[arg.name]
            }
        }

        //set the macro function arguments into context
        for arg in args {
            if let eval = try? await ctx.evaluate(value: "\(arg.value)", with: pInfo) {
                await ctx.variables.set(arg.name, value: eval)
            } else {
                throw TemplateSoup_ParsingError.invalidExpression_VariableOrObjPropNotFound(
                    arg.value, pInfo)
            }
        }

        //add function param as debug info
        await ctx.debugInfo.title("\(name) Function Params:-")
        for arg in args {
            if let value = await ctx.variables[arg.name] {
                await ctx.debugInfo.set(arg.name, value: value)
            } else {
                await ctx.debugInfo.set(arg.name, value: "nil")
            }
        }
            
        if let body = try await container.execute(with: ctx) {
            rendering += body
        }

        //remove the arvs from affecting rest of the context
        for arg in args {
            await ctx.variables.removeValue(forKey: arg.name)
        }

        //restore any variables clashing with the arguments
        for (key, _) in oldArgValues {
            await ctx.variables.set(key, value: oldArgValues[key])
        }

        //ctx.popSnapshot()

        return rendering.isNotEmpty ? rendering : nil
    }

    public func snapshot() async -> [TemplateItem] {
        await container.items
    }

    public func append(_ item: TemplateItem) async {
        await container.append(item)
    }

    public var debugDescription: String { get async {
        var str = """
            container: Macro Function Defn - \(await container.items.count) items
            - macro name: \(self.name)
            - params: \(self.params)
            
            """
        
        await str += container.debugStringForChildren()
        
        return str
    }}

    public init(name: String, params: [String], pInfo: ParsedInfo) {
        self.params = params
        self.name = name
        self.pInfo = pInfo

        container = GenericStmtsContainer(.macro, name: name)
    }
}
