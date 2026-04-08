import Foundation
import Testing
@testable import ModelHikeKit

@Test
func listBlueprintsIncludesBundledOfficialBlueprints() async throws {
    let engine = ModelHikeEngine()
    let result = try await engine.listBlueprints()
    var names = Set<String>()
    for blueprint in result.blueprints {
        names.insert(blueprint.name)
    }

    #expect(result.diagnostics.isEmpty)
    #expect(names.contains("api-nestjs-monorepo"))
    #expect(names.contains("api-springboot-monorepo"))
}

@Test
func dryRunUsesBundledOfficialBlueprint() async throws {
    let engine = ModelHikeEngine()
    let result = try await engine.dryRun(
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
            - status: String
            # APIs
            @ apis:: create, list, get-by-id
            #
            """
        ),
        blueprint: "api-nestjs-monorepo",
        containers: ["APIs"]
    )

    #expect(DiagnosticSummary(diagnostics: result.diagnostics).hasErrors == false)
    #expect(result.files.isEmpty == false)
    #expect(result.files.contains(where: { $0.path == "APIs/package.json" }))
    #expect(result.files.contains(where: { $0.path.hasSuffix("controller.ts") }))
    #expect(result.persisted == false)
    #expect(result.outputDirectory == nil)
}

@Test
func generatePersistsBundledOfficialBlueprintOutput() async throws {
    let engine = ModelHikeEngine()
    let outputRoot = FileManager.default.temporaryDirectory
        .appendingPathComponent("modelhike-smart-cli-generate-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: outputRoot) }

    let result = try await engine.generate(
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
            - status: String
            # APIs
            @ apis:: create, list, get-by-id
            #
            """
        ),
        blueprint: "api-nestjs-monorepo",
        containers: ["APIs"],
        outputPath: outputRoot.path
    )

    let packageJSON = outputRoot.appendingPathComponent("APIs/package.json")
    let controller = outputRoot.appendingPathComponent("APIs/apps/billing/src/subscription/controller.ts")

    #expect(DiagnosticSummary(diagnostics: result.diagnostics).hasErrors == false)
    #expect(result.files.isEmpty == false)
    #expect(result.persisted == true)
    #expect(result.outputDirectory == outputRoot.path)
    #expect(FileManager.default.fileExists(atPath: packageJSON.path))
    #expect(FileManager.default.fileExists(atPath: controller.path))
}
