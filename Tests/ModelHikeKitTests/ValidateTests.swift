import Foundation
import ModelHike
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
            if diagnostic.code == .w301 {
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

@Test
func validateReportsCodeLogicBlankLineErrorWithSource() async throws {
        let engine = ModelHikeEngine()
        let result = try await engine.validate(.content(
            """
            ===
            APIs
            ====
            + Pricing

            === Pricing ===

            Order
            =====
            * amount : Float
            ~ calculate(rate: Float) : Float
            ```
            |> DB-RAW primary
            |> SQL
            |  SELECT 1
            |> LET rows = _
            |> IF rate <= 0
            |return amount
            ```
            """
        ))

        #expect(result.valid == false)
        var separatorError: Diagnostic?
        var separatorErrorCount = 0
        for diagnostic in result.diagnostics {
            if diagnostic.code == .e618 {
                separatorErrorCount += 1
                separatorError = diagnostic
            }
        }
        #expect(separatorError != nil)
        #expect(separatorErrorCount == 1)
        #expect(separatorError?.source?.fileIdentifier == "stdin.modelhike")
        #expect((separatorError?.source?.lineNo ?? 0) > 0)
        #expect(separatorError?.source?.lineContent.contains("|> IF rate <= 0") == true)
}

@Test
func fixInsertsBlankLineForCodeLogicSeparatorError() async throws {
        let engine = ModelHikeEngine()
        let brokenModel = """
            ===
            APIs
            ====
            + Pricing

            === Pricing ===

            Order
            =====
            * amount : Float
            ~ calculate(rate: Float) : Float
            ```
            |> DB-RAW primary
            |> SQL
            |  SELECT 1
            |> LET rows = _
            |> IF rate <= 0
            |return amount
            ```
            """

        let result = try await engine.fix(.content(brokenModel), codes: ["E618"])

        #expect(result.fixed == true)
        #expect(result.applied.count == 1)
        #expect(result.applied[0].code == .e618)
        let fixedModel = try #require(result.model)
        #expect(fixedModel.contains("|> LET rows = _\n\n|> IF rate <= 0"))

        let validation = try await engine.validate(.content(fixedModel))
        #expect(validation.valid == true)
}
