//
//  OutputFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol RenderableFile {
    var filename: String {get}
    func render() throws
}

public protocol PersistableFile {
    var filename: String {get}
    func persist() throws
}

public protocol OutputFile : AnyObject, PersistableFile, CustomDebugStringConvertible {
    var outputPath: LocalPath? {get set}
}

public protocol CopyableFile : OutputFile {
    var outputPath: LocalPath? {get set}
}

