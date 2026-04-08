import Foundation
import Testing
import ModelHike
@testable import ModelHikeKit

@Test
func generateInlinePreviewsFilesFromInlineBlueprint() async throws {
    let engine = ModelHikeEngine()
    let blueprint = InlineBlueprintSnapshot(
        name: "inline-preview",
        scripts: ["main": " "],
        folders: ["_root_": ["Readme": "Hello from blueprint"]]
    )

    let result = try await engine.generateInline(
        .content(
            """
            ===
            APIs
            ====
            + Billing

            === Billing ===

            Subscription
            ============
            * _id: String
            * name: String
            """
        ),
        inlineBlueprint: blueprint,
        containers: ["APIs"]
    )

    #expect(result.persisted == false)
    #expect(result.outputDirectory == nil)
    #expect(result.diagnostics.isEmpty)
    #expect(result.files.isEmpty == false)
    #expect(result.files.contains(where: { $0.content.contains("Hello from blueprint") }))
}

@Test
func generateInlinePersistsFilesToRequestedOutputFolder() async throws {
    let engine = ModelHikeEngine()
    let outputRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("modelhike-smart-cli-inline-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputRoot) }

    let blueprint = InlineBlueprintSnapshot(
        name: "inline-persist",
        scripts: ["main": " "],
        folders: ["_root_": ["Note": "on-disk"]]
    )

    let result = try await engine.generateInline(
        .content(
            """
            ===
            APIs
            ====
            + Billing

            === Billing ===

            Subscription
            ============
            * _id: String
            """
        ),
        inlineBlueprint: blueprint,
        containers: ["APIs"],
        persist: true,
        outputPath: outputRoot.path
    )

    let notePath = try #require(result.files.first?.path)
    let noteURL = outputRoot.appendingPathComponent(notePath)

    #expect(result.persisted)
    #expect(result.outputDirectory == outputRoot.path)
    #expect(result.diagnostics.isEmpty)
    #expect(FileManager.default.fileExists(atPath: noteURL.path))
}

@Test
func generateInlineReportsErrorWhenBlueprintMissingMainScript() async throws {
    let engine = ModelHikeEngine()
    let blueprint = InlineBlueprintSnapshot(
        name: "inline-invalid",
        templates: ["Entity": "class {{ entity.name }} {}"]
    )

    let result = try await engine.generateInline(
        .content(
            """
            ===
            APIs
            ====
            + Billing

            === Billing ===

            Subscription
            ============
            * _id: String
            """
        ),
        inlineBlueprint: blueprint,
        containers: ["APIs"]
    )

    #expect(result.files.isEmpty)
    #expect(result.diagnostics.isEmpty == false)
}
