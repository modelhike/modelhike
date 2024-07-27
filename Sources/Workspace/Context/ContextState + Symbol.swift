//
// ContextState + Symbol.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

fileprivate let working_dir_var : String = "working_dir"
public typealias DebugDictionary = [String: TemplateSoupExpressionDebugInfo]

public extension Context {
    var variables: StringDictionary {
        get { currentState.variables }
        set { currentState.variables = newValue }
    }

    var debugInfo: DebugDictionary {
        get { currentState.debugInfo }
        set { currentState.debugInfo = newValue }
    }
    
    var macroFunctions: [String: MacroFunctionContainer]  {
        get { currentState.macroFunctions }
        set { currentState.macroFunctions = newValue }
    }
    
    var loopIsFirst: Bool { variables["__first"] as? Bool ?? false}
    var loopIsLast: Bool { variables["__last"] as? Bool ?? false}
    
    var workingDirectoryString: String { variables[working_dir_var] as? String ?? "" }
    var workingDirectory: LocalPath { paths.output.path / workingDirectoryString }

    func isWorkingDirectoryVariable(_ name: String) -> Bool {
        return name == working_dir_var
    }
}

public struct ContextState {
    public internal(set) var variables: StringDictionary = [:]
    public internal(set) var debugInfo: DebugDictionary = [:]
    public internal(set) var macroFunctions: [String: MacroFunctionContainer] = [:]
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

