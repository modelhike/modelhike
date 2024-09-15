//
// LocalFileModelLoader.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class LocalFileModelLoader : ModelRepository {
    let loadPath: LocalFolder
    let ctx: Context
    
    public var commonsFileName = "common.classes." + ModelConstants.ModelFile_Extension

    public func loadModel(to model: AppModel) throws {
        let file = LocalFile(path: loadPath.path / commonsFileName)
        
        if file.exists { //commons file found
            if let commonsContainer = try ModelFileParser(with: ctx).parse(file: file, with: ctx).containers.first {
                model.commonModel = commonsContainer.components
            }
        }
        
        for file in loadPath.files {
            if file.name != commonsFileName && file.extension == ModelConstants.ModelFile_Extension {
                let modelContainers = try ModelFileParser(with: ctx).parse(file: file, with: ctx)
                model.append(contentsOf: modelContainers.containers)
            }
        }
    }
    
    public init(path: LocalPath, with ctx: Context) {
        self.loadPath = LocalFolder(path: path) 
        self.ctx = ctx
    }
}
