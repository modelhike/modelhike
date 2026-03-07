//
//  DebugSession.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Describes one generated output file as it appears in the debug timeline.
/// The UI uses this record to build the file tree and map a file selection back
/// to the event window where that file was produced.
public struct GeneratedFileRecord: Codable, Sendable {
    /// Final output path recorded for the generated file.
    public let outputPath: String
    /// Template or script-level file name that initiated generation, if known.
    public let templateName: String?
    /// Model object name associated with this output, when generation is object-driven.
    public let objectName: String?
    /// Working directory active when the file was generated.
    public let workingDir: String
    /// Zero-based index into `DebugSession.events` for the file-generation event.
    public let eventIndex: Int

    public init(outputPath: String, templateName: String?, objectName: String?, workingDir: String, eventIndex: Int) {
        self.outputPath = outputPath
        self.templateName = templateName
        self.objectName = objectName
        self.workingDir = workingDir
        self.eventIndex = eventIndex
    }
}

/// Captures one error raised during pipeline execution together with the source
/// location, call stack, and optional variable dump that helps explain the failure.
public struct ErrorRecord: Codable, Sendable {
    /// Broad classification such as parsing, evaluation, or rendering.
    public let category: String
    /// Human-readable error message shown in the debug UI.
    public let message: String
    /// Primary source location where the error originated.
    public let source: SourceLocation
    /// Source-aware call stack collected at the time the error was recorded.
    public let callStack: [SourceLocation]
    /// Optional flattened variable state captured when the error occurred.
    public let memoryDump: [String: String]?

    public init(category: String, message: String, source: SourceLocation, callStack: [SourceLocation], memoryDump: [String: String]?) {
        self.category = category
        self.message = message
        self.source = source
        self.callStack = callStack
        self.memoryDump = memoryDump
    }
}

/// Summarizes one pipeline phase run, including timing and success/failure state.
public struct PhaseRecord: Codable, Sendable {
    /// Phase name such as Discover, Load, Render, or Persist.
    public let name: String
    /// When the phase started.
    public let startedAt: Date
    /// When the phase completed, if it finished.
    public let completedAt: Date?
    /// Elapsed seconds for the phase, if completion timing was recorded.
    public let duration: Double?
    /// Whether the phase completed successfully.
    public let success: Bool
    /// Error text for a failed phase, if one was recorded.
    public let errorMessage: String?

    public init(name: String, startedAt: Date, completedAt: Date?, duration: Double?, success: Bool, errorMessage: String?) {
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.duration = duration
        self.success = success
        self.errorMessage = errorMessage
    }
}

/// Snapshot of the pipeline configuration relevant to the debug run.
/// This lets the UI explain what model folder and output folder were used.
public struct ConfigSnapshot: Codable, Sendable {
    /// Model/input root used for discovery and loading.
    public let basePath: String
    /// Root output folder for generated artifacts.
    public let outputPath: String
    /// Container names selected for generation in this run.
    public let containersToOutput: [String]

    public init(basePath: String, outputPath: String, containersToOutput: [String]) {
        self.basePath = basePath
        self.outputPath = outputPath
        self.containersToOutput = containersToOutput
    }
}

/// Complete serializable payload for a debug run.
/// This is the top-level object served to the browser-based debug console, combining
/// timeline events, source files, generated-file metadata, model snapshots, errors,
/// and memory snapshots into a single session document.
public struct DebugSession: Codable, Sendable {
    /// When the session snapshot was assembled.
    public let timestamp: Date
    /// Configuration used for the run.
    public let config: ConfigSnapshot
    /// Per-phase status and timing information.
    public let phases: [PhaseRecord]
    /// Structural snapshot of the loaded model for explorer views.
    public let model: ModelSnapshot
    /// Full ordered event timeline captured during execution.
    public let events: [DebugEventEnvelope]
    /// Source/template/script files registered for source lookup in the UI.
    public let sourceFiles: [SourceFile]
    /// Generated output files and their linkage into the event timeline.
    public let files: [GeneratedFileRecord]
    /// Errors captured during the run.
    public let errors: [ErrorRecord]
    /// Full-memory checkpoints used for time-travel variable reconstruction.
    public let baseSnapshots: [MemorySnapshot]
    /// Incremental variable changes applied on top of base snapshots.
    public let deltaSnapshots: [DeltaSnapshot]

    public init(timestamp: Date, config: ConfigSnapshot, phases: [PhaseRecord], model: ModelSnapshot, events: [DebugEventEnvelope], sourceFiles: [SourceFile], files: [GeneratedFileRecord], errors: [ErrorRecord], baseSnapshots: [MemorySnapshot], deltaSnapshots: [DeltaSnapshot]) {
        self.timestamp = timestamp
        self.config = config
        self.phases = phases
        self.model = model
        self.events = events
        self.sourceFiles = sourceFiles
        self.files = files
        self.errors = errors
        self.baseSnapshots = baseSnapshots
        self.deltaSnapshots = deltaSnapshots
    }
}
