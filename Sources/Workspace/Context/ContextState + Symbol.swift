//
//  ContextState + Symbol.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public typealias DebugDictionary = [String: TemplateSoupExpressionDebugInfo]

public struct ContextState {
    public internal(set) var variables = WorkingMemory()
    public internal(set) var debugInfo: DebugDictionary = [:]
    public internal(set) var templateFunctions = TemplateFunctionMap()
}

public struct ContextSymbols {
    public internal(set) var template = TemplateSoupSymbols()
    public internal(set) var models = ModelSymbols()
}

public struct TemplateSoupExpressionDebugInfo {
    var output: Any
    var expression: String
    var variables: StringDictionary
}

