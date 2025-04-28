//
//  SendableDebug.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol SendableDebugStringConvertible: Sendable {
    var debugDescription: String { get async }
}

public protocol SendableStringConvertible: Sendable {
    var description: String { get async }
}
