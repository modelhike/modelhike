//
//  MemorySnapshot.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// A full variable snapshot at a moment in the debug timeline.
/// This is the baseline state the debugger starts from when reconstructing memory.
public struct MemorySnapshot: Codable, Sendable {
    public let label: String
    public let timestamp: Date
    /// Zero-based index into `DebugSession.events`. This snapshot becomes the base state
    /// for reconstructing variables at this event index and later indices.
    public let eventIndex: Int
    public let variables: [String: String]

    public init(label: String, timestamp: Date, eventIndex: Int, variables: [String: String]) {
        self.label = label
        self.timestamp = timestamp
        self.eventIndex = eventIndex
        self.variables = variables
    }
}

/// A single variable change recorded after a base snapshot.
/// Instead of storing the full memory state again, the debugger applies these deltas
/// on top of the nearest `MemorySnapshot` to rebuild state for later events.
public struct DeltaSnapshot: Codable, Sendable {
    /// Zero-based index into `DebugSession.events` where this variable change should be
    /// considered visible during state reconstruction.
    public let eventIndex: Int
    public let variable: String
    public let oldValue: String?
    public let newValue: String

    public init(eventIndex: Int, variable: String, oldValue: String?, newValue: String) {
        self.eventIndex = eventIndex
        self.variable = variable
        self.oldValue = oldValue
        self.newValue = newValue
    }
}
