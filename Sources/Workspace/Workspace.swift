//
// Workspace.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class Workspace {
    var model: AppModel
    public internal(set) var isModelsLoaded = false
    public internal(set) var context: LoadContext
    public internal(set) var config: PipelineConfig
    
    public func newSandbox() -> Sandbox {
        return CodeGenerationSandbox(model: self.model, config: config)
    }
    
    public func render(string input: String, data: [String : Any]) throws -> String? {
        let sandbox = newSandbox()

        let rendering = try sandbox.render(string: input, data: data)
        return rendering?.trim()
    }
        
    internal init() {
        let config = PipelineConfig()
        let model = AppModel()
        
        self.config = config
        self.model = model
        self.context = LoadContext(model: model, config: config)
    }
}

public enum PreDefinedSymbols {
    case typescript, mongodb_typescript, java, noMocking
}
