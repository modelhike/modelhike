//
//  Pipelines.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum Pipelines {
    
    public static var codegen: Pipeline { get async {
        await Pipeline {
            Discover.models()
            Load.models()
            Hydrate.models()
            Hydrate.annotations()
            Render.code()
            Persist.toOutputFolder()
        }}}
    
    public static var content: Pipeline { get async {
        await Pipeline {
            Load.contentsFrom(folder: "contents")
            LoadPagesPass(folderName: "localFolder")
            LoadTemplatesPass(folderName: "localFolder")
        }}}
    
    public static var empty: Pipeline { get async {
        await Pipeline {}
    }}
}
