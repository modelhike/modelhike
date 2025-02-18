//
// ContextState + Symbol.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias DebugDictionary = [String: TemplateSoupExpressionDebugInfo]

public struct ContextState {
    public internal(set) var variables: StringDictionary = [:]
    public internal(set) var debugInfo: DebugDictionary = [:]
    public internal(set) var templateFunctions: [String: TemplateFunctionContainer] = [:]
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

