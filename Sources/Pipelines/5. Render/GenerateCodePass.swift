//
// GenerateCodePass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateCodePass : RenderingPass {
    public func canRunIn(phase: RenderPhase) throws -> Bool {

        if !phase.context.model.isModelsLoaded {
            let pInfo = ParsedInfo.dummyForAppState(with: phase.context)
            throw EvaluationError.invalidAppState("No models Loaded!!!", pInfo)
        }
        
        return true
    }
    
    public func runIn(_ sandbox: GenerationSandbox, phase: RenderPhase) async throws -> Bool {
        
        var templatesRepo: Blueprint
        
        let blueprint = "api-nestjs-monorepo"
        //let blueprint = "api-springboot-monorepo"
        
        if blueprint == "api-nestjs-monorepo" {
            try sandbox.loadSymbols([.typescript, .mongodb_typescript])
        } else if blueprint == "api-springboot-monorepo" {
            try sandbox.loadSymbols([.java])
        }
        
        let pInfo = ParsedInfo.dummyForAppState(with: sandbox.context)
        templatesRepo = try sandbox.config.blueprint(named: blueprint, with: pInfo)
        
        if phase.config.outputIten == .container {
            //if there is only one container in the model, generate for that container
            if sandbox.model.containers.count == 1, let container = sandbox.model.containers.first {
                let containerName = container.name
                try generateCodebase(container: containerName, usingBlueprintsFrom: templatesRepo, sandbox: sandbox)
            } else if phase.config.containersToOutput.count > 0 { //get from config
                for container in phase.config.containersToOutput {
                    try generateCodebase(container: container, usingBlueprintsFrom: templatesRepo, sandbox: sandbox)
                }
            } else {
                throw EvaluationError.invalidAppState("Please specify a container, container group or system view to output", pInfo)
            }
        }
                        
        return true
    }
    
    @discardableResult
    public func generateCodebase(container: String, usingBlueprintsFrom blueprintLoader: Blueprint, sandbox: GenerationSandbox) throws -> String? {
        var mutableSandbox = sandbox
        let output = sandbox.config.output
        
        print("🛠️ Container used: \(container)")
        print("🛠️ Output folder: \(output.path.string)")
        
        let rendering = try mutableSandbox.generateFilesFor(container: container, usingBlueprintsFrom: blueprintLoader)
        
        return rendering
    }
    fileprivate func printError(_ err: Error, workspace: Workspace) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: workspace)
    }
    
    public init() {
    }
}
