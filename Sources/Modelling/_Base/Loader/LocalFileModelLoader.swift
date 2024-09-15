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
            let commons = try ModelFileParser(with: ctx)
                                            .parse(file: file, with: ctx)
            
            model.appendToCommonModel(contentsOf: commons)
        }
        
        for file in loadPath.files {
            if file.name != commonsFileName && file.extension == ModelConstants.ModelFile_Extension {
                let modelSpace = try ModelFileParser(with: ctx)
                                                .parse(file: file, with: ctx)
                
                model.append(contentsOf: modelSpace)
            }
        }
        
        model.resolveAndLinkItems()
    }
    
    public init(path: LocalPath, with ctx: Context) {
        self.loadPath = LocalFolder(path: path) 
        self.ctx = ctx
    }
}
