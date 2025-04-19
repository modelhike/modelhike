//
//  GenerateCodePass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor GenerateCodePass : RenderingPass {
    public func canRunIn(phase: RenderPhase) async throws -> Bool {

        if await !phase.context.model.isModelsLoaded {
            let pInfo = await ParsedInfo.dummyForAppState(with: phase.context)
            throw EvaluationError.invalidAppState("No models Loaded!!!", pInfo)
        }
        
        return true
    }
    
    public func runIn(_ sandbox: GenerationSandbox, phase: RenderPhase) async throws -> Bool {
        
        var templatesRepo: Blueprint
        
        let blueprint = "api-nestjs-monorepo"
        //let blueprint = "api-springboot-monorepo"
        
        if blueprint == "api-nestjs-monorepo" {
            try await sandbox.loadSymbols([.typescript, .mongodb_typescript])
        } else if blueprint == "api-springboot-monorepo" {
            try await sandbox.loadSymbols([.java])
        }
        
        let pInfo = await ParsedInfo.dummyForAppState(with: sandbox.context)
        templatesRepo = try await sandbox.context.blueprint(named: blueprint, with: pInfo)
        
        if await phase.config.outputItemType == .container {
            //if there is only one container in the model, generate for that container
            if await sandbox.model.containers.count == 1, let container = await sandbox.model.containers.first {
                let containerName = await container.name
                try await generateCodebase(container: containerName, usingBlueprintsFrom: templatesRepo, sandbox: sandbox)
            } else if await phase.config.containersToOutput.count > 0 { //get from config
                for container in await phase.config.containersToOutput {
                    try await generateCodebase(container: container, usingBlueprintsFrom: templatesRepo, sandbox: sandbox)
                }
            } else {
                throw EvaluationError.invalidAppState("Please specify a container, container group or system view to output", pInfo)
            }
        }
                        
        return true
    }
    
    @discardableResult
    public func generateCodebase(container: String, usingBlueprintsFrom blueprintLoader: Blueprint, sandbox: GenerationSandbox) async throws -> String? {
        let output = await sandbox.config.output
        
        print("🛠️ Container used: \(container)")
        print("🛠️ Output folder: \(output.path.string)")
        
        let rendering = try await sandbox.generateFilesFor(container: container, usingBlueprintsFrom: blueprintLoader)
        
        return rendering
    }
    
    fileprivate func printError(_ err: Error, workspace: Workspace) async {
        let printer = PipelineErrorPrinter()
        await printer.printError(err, workspace: workspace)
    }
    
    public init() {
    }
}
