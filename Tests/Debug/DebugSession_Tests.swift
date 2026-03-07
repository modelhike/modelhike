//
//  DebugSession_Tests.swift
//  ModelHikeTests
//

import Foundation
import Testing
@testable import ModelHike

@Suite struct DebugSession_Tests {

    @Test func sessionEncodesToJSON() async throws {
        let session = DebugSession(
            timestamp: Date(),
            config: ConfigSnapshot(basePath: "/tmp", outputPath: "/out", containersToOutput: ["APIs"]),
            phases: [
                PhaseRecord(name: "Discover", startedAt: Date(), completedAt: Date(), duration: 0.1, success: true, errorMessage: nil)
            ],
            model: ModelSnapshot(containers: []),
            events: [],
            sourceFiles: [],
            files: [],
            errors: [],
            baseSnapshots: [],
            deltaSnapshots: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json != nil)
        #expect(json?["phases"] != nil)
        #expect(json?["model"] != nil)
        #expect(json?["events"] != nil)
        #expect(json?["files"] != nil)
    }

    @Test func sessionWithEventsHasCorrectStructure() async throws {
        let envelope = DebugEventEnvelope(
            sequenceNo: 1,
            timestamp: Date(),
            containerName: "APIs",
            event: .fileGenerated(outputPath: "foo.ts", templateName: "entity.teso", objectName: "User", source: SourceLocation(fileIdentifier: "main.ss", lineNo: 1, lineContent: "x", level: 0))
        )
        let session = DebugSession(
            timestamp: Date(),
            config: ConfigSnapshot(basePath: "/tmp", outputPath: "/out", containersToOutput: []),
            phases: [],
            model: ModelSnapshot(containers: []),
            events: [envelope],
            sourceFiles: [],
            files: [],
            errors: [],
            baseSnapshots: [],
            deltaSnapshots: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DebugSession.self, from: data)
        #expect(decoded.events.count == 1)
    }
}
