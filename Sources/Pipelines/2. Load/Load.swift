//
//  Load.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum Load {
    static func models() -> LoadingPass {
        LoadModelsPass()
    }
}

public extension Load {
    static func contentsFrom(folder localFolder: String, afterModifiedDate: Date? = nil) -> LoadingPass {
        LoadContentFromFolder(folderName: localFolder, afterModifiedDate: afterModifiedDate)
    }
    
    static func contentsFrom(notion localFolder: String) -> LoadingPass {
        LoadContentFromFolder(folderName: localFolder)
    }
}
