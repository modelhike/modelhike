//
// GenerateFiles.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GenerateFiles : PersistancePass {
    public func runIn(phase: PersistPhase) async -> Bool {
        return true
    }
}
