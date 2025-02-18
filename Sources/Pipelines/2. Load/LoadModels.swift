//
// LoadModelsPass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct LoadModelsPass : LoadingPass {

    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        var repo: ModelRepository

        do {
            //        if config.modelLoaderType == .localFileSystem {
            repo = LocalFileModelLoader(path: ws.config.basePath, with: ws.context)
            //let modelRepo = inlineModel(ws)
            
            try repo.loadModel(to: ws.model)
            try repo.loadGenerationConfigIfAny()
            
            try repo.processAfterLoad(model: ws.model, with: ws.context)
            
            if ws.model.types.items.count > 0 {
                ws.isModelsLoaded = true
            }
        } catch let err {
            printError(err, workspace: ws)
            print("❌❌ ERROR IN LOADING MODELS ❌❌")
        }
        return true
    }
    
    fileprivate func printError(_ err: Error, workspace: Workspace) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: workspace)
    }
    
    public init() {
    }
}
