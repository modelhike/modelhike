//
//  OutputFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol RenderableFile: Actor {
    var filename: String {get}
    func render() async throws
}

public protocol PersistableFile : Actor {
    var filename: String {get}
    func persist() async throws
}

public protocol OutputFile : Actor, PersistableFile, SendableDebugStringConvertible { //AnyObject
    var outputPath: LocalPath? {get}
    func outputPath(_ value: LocalPath)
}

public protocol CopyableFile : OutputFile {
    
}

