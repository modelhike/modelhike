//
// LocalFileModelLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LocalFileModelLoader : ModelRepository {
    let loadPath: LocalFolder
    let ctx: LoadContext
    
    public var commonsFileName = "common." + ModelConstants.ModelFile_Extension
    public let configFileName = TemplateConstants.MainTemplateFile + "." + ModelConstants.ConfigFile_Extension

    public func loadModel(to model: AppModel) throws {
        if !loadPath.exists {
            let pInfo = ParsedInfo.dummyForAppState(with: ctx)
            throw EvaluationError.invalidAppState("Model folder '\(loadPath.path.string)' not found!!!", pInfo)
        }
        
        let file = LocalFile(path: loadPath.path / commonsFileName)
        
        if file.exists { //commons file found
            let commons = try ModelFileParser(with: ctx)
                                            .parse(file: file)
            
            model.appendToCommonModel(contentsOf: commons)
        }
        
        for file in loadPath.files {
            if file.name != commonsFileName && file.extension == ModelConstants.ModelFile_Extension {
                let modelSpace = try ModelFileParser(with: ctx)
                                                .parse(file: file)
                
                model.append(contentsOf: modelSpace)
            }
        }
        
        try model.resolveAndLinkItems(with: ctx)
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
