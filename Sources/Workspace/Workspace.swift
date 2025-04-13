//
//  Workspace.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor Workspace {
    public internal(set) var context: LoadContext
    public var config: OutputConfig { get async { await self.context.config }}
    
    public func config(_ value: OutputConfig) async {
        await self.context.config(value)
    }
    
    var model: AppModel { context.model }
    public internal(set) var isModelsLoaded: Bool {
        get async { await model.isModelsLoaded }
        set { model.isModelsLoaded = newValue }
    }
    
    public func newGenerationSandbox() async -> GenerationSandbox {
        let loadedVars = await context.variables
        let sandbox = await CodeGenerationSandbox(model: self.model, config: config)
        await sandbox.context.append(variables: loadedVars)
        
        return sandbox
    }
    
    public func newStringSandbox() async -> Sandbox {
        let sandbox = await CodeGenerationSandbox(model: self.model, config: config)
        return sandbox
    }
    
    public func render(string input: String, data: [String : Sendable]) async throws -> String? {
        let sandbox = await newStringSandbox()

        let rendering = try sandbox.render(string: input, data: data)
        return rendering?.trim()
    }
        
    internal init() async {
        let config = PipelineConfig()
        
        await self.config(config)
        self.context = LoadContext(config: config)
    }
}

public enum PreDefinedSymbols {
    case typescript, mongodb_typescript, java, noMocking
}
