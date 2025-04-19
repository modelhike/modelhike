//
//  ScriptFile.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Script: Sendable, StringConvertible {
    var name: String { get }
}

public protocol ScriptFile: Script {

}
