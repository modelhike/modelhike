//
//  LoadModelsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct LoadModelsPass: LoadingPass {

    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        var repo: ModelRepository

        do {
            //TODO: Also update in Discover phase
            //        if config.modelLoaderType == .localFileSystem {
            repo = LocalFileModelLoader(path: ws.config.basePath, with: ws.context)
            //let modelRepo = inlineModel(ws)

            try repo.loadModel(to: ws.model)
            try repo.loadGenerationConfigIfAny()

            if ws.model.types.items.count > 0 {
                ws.isModelsLoaded = true

                let domainTypesCount = ws.model.containers.types.count
                let commonTypesCount = ws.model.commonModel.types.count
                print(
                    "💡 Loaded domain types: \(domainTypesCount), common types: \(commonTypesCount)")

                return true

            } else {
                ws.isModelsLoaded = false
                print("❌❌ No Model Found!!!")
                return false
            }
        } catch let err {
            printError(err, workspace: ws)
            print("❌❌ ERROR IN LOADING MODELS ❌❌")
            return false
        }
    }

    fileprivate func printError(_ err: Error, workspace: Workspace) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: workspace)
    }

    public init() {
    }
}
