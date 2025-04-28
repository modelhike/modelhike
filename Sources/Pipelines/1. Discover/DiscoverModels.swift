//
//  DiscoverModelsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct DiscoverModelsPass : DiscoveringPass {

    public func runIn(_ ws: Workspace, phase: DiscoverPhase) async throws -> Bool {
        var repo: ModelRepository

        //TODO: Also update in Load phase
        //        if config.modelLoaderType == .localFileSystem {
        repo = await LocalFileModelLoader(path: ws.config.basePath, with: ws.context)
        //let modelRepo = inlineModel(ws)
        
        if repo.probeForGenerationConfig() {
            //print("Generation Config Found!!!")
        }
        
        if repo.probeForCommonModelFiles() {
            //print("Common Model Files Found!!!")
        }
        
        if !repo.probeForModelFiles() {
            print("❌❌ No Model Files Found!!!")
            return false
        }
        
        return true
    }
    
    public init() {
    }
}
