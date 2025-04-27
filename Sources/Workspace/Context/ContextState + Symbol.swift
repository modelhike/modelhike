//
//  ContextState + Symbol.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public final class ContextState: Sendable {
    public let variables = WorkingMemory()
    public let debugInfo = DebugDictionary()
    public let templateFunctions = TemplateFunctionMap()
}

public actor DebugDictionary{
    var debugInfo: [String: TemplateSoupExpressionDebugInfo] = [:]
}

public actor ContextSymbols {
    public internal(set) var template = TemplateSoupSymbols()
    public internal(set) var models = ModelSymbols()
    
    public func addTemplate(modifiers modifiersList: [Modifier]) {
        template.add(modifiers: modifiersList)
    }
    
    public func addTemplate(stmts stmtsList: [any FileTemplateStmtConfig]) {
        template.add(stmts: stmtsList)
    }
    
    public func addTemplate(infixOperators operatorsList: [InfixOperatorProtocol]) {
        template.add(infixOperators: operatorsList)
    }
}

public struct TemplateSoupExpressionDebugInfo: Sendable {
    var output: Sendable
    var expression: String
    var variables: StringDictionary
}

