//
// Workspace.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class Workspace {
    public internal(set) var context: LoadContext
    public internal(set) var config: PipelineConfig
    var model: AppModel { context.model }
    public internal(set) var isModelsLoaded: Bool {
        get { model.isModelsLoaded }
        set { model.isModelsLoaded = newValue }
    }
    
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
        
        self.config = config
        self.context = LoadContext(config: config)
    }
}

public enum PreDefinedSymbols {
    case typescript, mongodb_typescript, java, noMocking
}
