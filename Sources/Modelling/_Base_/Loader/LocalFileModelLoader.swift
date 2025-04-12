//
//  LocalFileModelLoader.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class LocalFileModelLoader : ModelRepository {
    let loadPath: LocalFolder
    let ctx: LoadContext
    
    public var commonModelsFileName = "common." + ModelConstants.ModelFile_Extension
    public let configFileName = TemplateConstants.MainScriptFile + "." + ModelConstants.ConfigFile_Extension

    public func loadModel(to model: AppModel) throws {
        if !loadPath.exists {
            let pInfo = ParsedInfo.dummyForAppState(with: ctx)
            throw EvaluationError.invalidAppState("Model folder '\(loadPath.path.string)' not found!!!", pInfo)
        }
        
        let file = LocalFile(path: loadPath.path / commonModelsFileName)
        
        if file.exists { //commons file found
            let commons = try ModelFileParser(with: ctx)
                                            .parse(file: file)
            
            model.appendToCommonModel(contentsOf: commons)
        }
        
        for file in loadPath.files {
            if file.name != commonModelsFileName && file.extension == ModelConstants.ModelFile_Extension {
                let modelSpace = try ModelFileParser(with: ctx)
                                                .parse(file: file)
                
                model.append(contentsOf: modelSpace)
            }
        }
        
        try model.resolveAndLinkItems(with: ctx)
    }
    
    public func probeForModelFiles() -> Bool {
        for file in loadPath.files {
            if file.name != commonModelsFileName && file.extension == ModelConstants.ModelFile_Extension {
                return true
            }
        }
        
        return false
    }
    
    public func probeForCommonModelFiles() -> Bool {
        let file = LocalFile(path: loadPath.path / commonModelsFileName)
        
        if file.exists { //common model file found
            return true
        } else {
            return false
        }
    }
    
    public func probeForGenerationConfig() -> Bool {
        let file = LocalFile(path: loadPath.path / configFileName)
        
        if file.exists { //config file found
            return true
        } else {
            return false
        }
    }
    
    public func loadGenerationConfigIfAny() throws {
        let file = LocalFile(path: loadPath.path / configFileName)
        
        if file.exists { //config file found
            try ConfigFileParser(with: ctx)
                .parse(file: file)
        }
    }
    
    public init(path: LocalPath, with ctx: LoadContext) {
        self.loadPath = LocalFolder(path: path)
        self.ctx = ctx
    }
}
