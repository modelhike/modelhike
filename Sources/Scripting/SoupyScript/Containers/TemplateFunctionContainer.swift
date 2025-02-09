//
// TemplateFunctionContainer.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class TemplateFunctionContainer : TemplateStmtContainer {
    let container : GenericStmtsContainer
    
    let params: [String]
    let name: String
    let pInfo: ParsedInfo
    
    public func execute(args: [ArgumentDeclaration], with ctx: Context) throws -> String? {
        var rendering = ""

        //IMPORTANT : ctx push/pop should not be used here as 
        //any variable modification
        //that is done inside the template fn body should be persisted
        //only the template fn args are to be removed after execution
        //so, the template fn args are removed manually
        
        //ctx.pushSnapshot()
        
        //backup any variables clashing with the arguments
        var oldArgValues : StringDictionary = [:]
        for arg in args {
            if ctx.variables.has(arg.name) {
                oldArgValues[arg.name] = ctx.variables[arg.name]
            }
        }
        
        //set the macro function arguments into context
        for arg in args {
            ctx.variables[arg.name] = try? ctx.evaluate(value: "\(arg.value)", with: pInfo )
        }
        
        if let body = try container.execute(with: ctx) {
            rendering += body
        }
        
        //remove the arvs from affecting rest of the context
        for arg in args {
            ctx.variables.removeValue(forKey: arg.name)
        }
        
        //restore any variables clashing with the arguments
        for (key, _) in oldArgValues {
            ctx.variables[key] = oldArgValues[key]
        }
        
        //ctx.popSnapshot()
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public func next() -> TemplateItem? {
        return container.next()
    }
    
    public func append(_ item: TemplateItem) {
        container.append(item)
    }
    
    public var debugDescription: String {
        var str =  """
        container: Macro Function Defn - \(container.items.count) items
        - macro name: \(self.name)
        - params: \(self.params)
        
        """
        
        str += container.debugStringForChildren()
        
        return str
    }
    
    public init(name: String, params: [String], pInfo: ParsedInfo) {
        self.params = params
        self.name = name
        self.pInfo = pInfo
        
        container = GenericStmtsContainer(.macro, name: name)
    }
}
