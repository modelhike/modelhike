//
//  Modifiers.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum Modifiers  {
    public static func apply<T: Sendable>(to value: T, modifiers: [ModifierInstance], with pInfo: ParsedInfo) async throws -> Sendable? {
        var result : T = value
        for modifier in modifiers {
            if let resultValue = try modifier.applyTo(value: result, with: pInfo) as? T {
                result = resultValue
            } else {
                return nil
            }
        }
        
        return result
    }
    
    public static func parse(string: String?, pInfo: ParsedInfo) async throws -> [ModifierInstance] {
        guard let string = string else { return [] }
        
        let components = string.trim().split(separator: TemplateConstants.multiModifierSplit).trim()
        guard components.count > 0 else { return [] }
        
        let context = pInfo.ctx
        var result : [ModifierInstance] = []
        
        for component in components {
            let str = String(component)
            
            if str.isPattern(CommonRegEx.functionName) { //without any args
                
                if let modifierSymbol = await context.symbols.template.modifiers[str] as? ModifierWithoutArgsProtocol {
                    let instance = modifierSymbol.instance()
                    
                    result.append(instance)
                } else {
                    throw TemplateSoup_ParsingError.modifierInvalidSyntax(str, pInfo)
                }

            } else if let match = str.wholeMatch(of: CommonRegEx.functionInvocation_unNamedArgs_Capturing) {
                
                let (_, fnName, argsString) = match.output

                if let modifierSymbol = await context.symbols.template.modifiers[fnName] as? ModifierWithUnNamedArgsProtocol {
                    
                    let args = await argsString.split(separator: ",").compactMap { 
                        $0.trim().isNotEmpty ? String($0) : nil }
                    
                    let instance = modifierSymbol.instance()
                    if var instanceWithUnNamedArgs = instance as? ModifierInstanceWithUnNamedArgsProtocol {
                        
                        instanceWithUnNamedArgs.setArgsGiven(arguments: args)
                        result.append(instanceWithUnNamedArgs)
                    }
                } else {
                    throw TemplateSoup_ParsingError.modifierInvalidSyntax(str, pInfo)
                }
            } else {
                throw TemplateSoup_ParsingError.modifierNotFound(str, pInfo)
            }
        }
        
        return result
    }
}

public extension Array where Element == ModifierInstance {
    func nameString() -> String {
        var modifiersStr = "none"

        if self.count > 0 {
            modifiersStr = self.reduce("") { (res, item) in
                return res + item.name
            }
        }
        
        return modifiersStr
    }
}
