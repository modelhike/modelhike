//
//  PluginsPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor PluginsPass: TransformationPass {
    public func runIn(phase: TransformPhase) async -> Bool {
        return true
    }
}
