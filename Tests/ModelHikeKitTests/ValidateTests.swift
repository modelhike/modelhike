import Foundation
import Testing
@testable import ModelHikeKit

@Test
func validateReportsUnresolvedType() async throws {
        let engine = ModelHikeEngine()
        let result = try await engine.validate(.content(
            """
            ===
            APIs
            ====
            + Registry Management

            === Registry Management ===

            Subscription
            ============
            * _id: String
            * owner: CustomerProfile
            """
        ))

        #expect(result.valid == false)
        var unresolvedType: Diagnostic?
        for diagnostic in result.diagnostics {
            if diagnostic.code == "W301" {
                unresolvedType = diagnostic
                break
            }
        }
        #expect(unresolvedType != nil)
        #expect(unresolvedType?.source?.fileIdentifier == "stdin.modelhike")
        #expect((unresolvedType?.source?.lineNo ?? 0) > 0)
}

@Test
func validateReportsParseErrorSourceForFileInput() async throws {
        let engine = ModelHikeEngine()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("modelhike-smart-cli-validate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("broken.modelhike")
        try """
            ===
            APIs
            ====
            + Registry Management

            === Registry Management ===

            Subscription
            ============
            * _id: String
            * owner CustomerProfile
            """.write(to: fileURL, atomically: true, encoding: .utf8)

        let result = try await engine.validate(.file(fileURL.path))

        #expect(result.valid == false)
        #expect(result.diagnostics.contains(where: {
            $0.source?.fileIdentifier == "broken.modelhike" && ($0.source?.lineNo ?? 0) > 0
        }))
}
