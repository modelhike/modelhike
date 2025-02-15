//
// PluginsPass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct PluginsPass : TransformationPass {
    public func runIn(phase: TransformPhase) async -> Bool {
        return true
    }
}
