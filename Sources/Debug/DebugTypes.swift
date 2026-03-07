//
//  DebugTypes.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

// MARK: - Branch Kind

public enum BranchKind: String, Codable, Sendable {
    case ifTrue
    case elseIfTrue
    case elseBlock
}

// MARK: - Debug Event Envelope

public struct DebugEventEnvelope: Codable, Sendable {
    public let sequenceNo: Int
    public let timestamp: Date
    public let containerName: String?
    public let event: DebugEvent

    public init(sequenceNo: Int, timestamp: Date, containerName: String?, event: DebugEvent) {
        self.sequenceNo = sequenceNo
        self.timestamp = timestamp
        self.containerName = containerName
        self.event = event
    }
}
