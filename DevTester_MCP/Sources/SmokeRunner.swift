import Foundation
import MCP

struct SmokeRunConfiguration: Sendable {
    let launch: ChildProcessLaunchConfiguration
    let timeoutSeconds: Double
    let blueprint: String
    let entity: String
    let validModelContent: String
    let invalidModelContent: String
    let selectedTools: [SmokeTool]
    let expectations: SmokeExpectations
    let verbose: Bool
    let includeStderr: Bool
}

struct SmokeExpectations: Sendable {
    let expectedAdvertisedTools: Set<String>
    let expectedDiagnosticCodes: [String]
    let expectedEntityCount: Int?
    let expectedReferences: [String]
    let expectedDependents: [String]
    let expectedBlueprints: [String]
    let expectedGeneratedSuffixes: [String]
}

struct SmokeSummary: Codable, Sendable {
    let success: Bool
    let durationMs: Int
    let launch: ChildProcessLaunchConfiguration
    let initialize: InitializeSummary?
    let checks: [SmokeCheckResult]
    let stderrTail: String?
}

struct InitializeSummary: Codable, Sendable {
    let protocolVersion: String
    let serverName: String
    let serverVersion: String
}

struct SmokeCheckResult: Codable, Sendable {
    let name: String
    let passed: Bool
    let details: Value?
    let error: String?
}

enum SmokeTool: String, CaseIterable, Codable, Sendable {
    case validate = "modelhike/validate"
    case generate = "modelhike/generate"
    case explain = "modelhike/explain"
    case inspect = "modelhike/inspect"
    case whatDependsOn = "modelhike/what-depends-on"
    case listBlueprints = "modelhike/list-blueprints"
    case schemaInMarkdown = "modelhike/schema-in-markdown"
}

struct SmokeRunner {
    let configuration: SmokeRunConfiguration

    func run() async -> SmokeSummary {
        let start = Date()
        let transport = ChildProcessTransport(configuration: configuration.launch)
        let client = Client(name: "DevTester_MCP", version: "1.0.0")

        var initialize: InitializeSummary?
        var checks: [SmokeCheckResult] = []

        do {
            let initializeResult = try await withTimeout(
                "initialize",
                seconds: configuration.timeoutSeconds
            ) {
                try await client.connect(transport: transport)
            }

            initialize = InitializeSummary(
                protocolVersion: initializeResult.protocolVersion,
                serverName: initializeResult.serverInfo.name,
                serverVersion: initializeResult.serverInfo.version
            )
        } catch {
            let stderr = await nonEmptyStderr(from: transport)
            checks.append(
                SmokeCheckResult(
                    name: "initialize",
                    passed: false,
                    details: nil,
                    error: decorate(error.localizedDescription, stderr: stderr)
                )
            )

            await client.disconnect()
            await transport.disconnect()

            return SmokeSummary(
                success: false,
                durationMs: elapsedMilliseconds(since: start),
                launch: configuration.launch,
                initialize: initialize,
                checks: checks,
                stderrTail: stderr
            )
        }

        do {
            let toolList = try await withTimeout(
                "tools/list",
                seconds: configuration.timeoutSeconds
            ) {
                try await client.listTools()
            }

            let advertisedTools = toolList.tools.map(\.name)
            let missingTools = configuration.expectations.expectedAdvertisedTools.subtracting(advertisedTools)
            checks.append(
                SmokeCheckResult(
                    name: "tools/list",
                    passed: missingTools.isEmpty,
                    details: .object([
                        "advertisedTools": .array(advertisedTools.map(Value.string)),
                        "missingTools": .array(missingTools.sorted().map(Value.string)),
                    ]),
                    error: missingTools.isEmpty ? nil : "Missing advertised tools: \(missingTools.sorted().joined(separator: ", "))"
                )
            )
        } catch {
            checks.append(
                SmokeCheckResult(
                    name: "tools/list",
                    passed: false,
                    details: nil,
                    error: error.localizedDescription
                )
            )
        }

        for tool in configuration.selectedTools {
            let result = await runTool(tool, client: client)
            checks.append(result)
        }

        let stderr = await nonEmptyStderr(from: transport)

        await client.disconnect()
        await transport.disconnect()

        let success = checks.allSatisfy(\.passed)
        return SmokeSummary(
            success: success,
            durationMs: elapsedMilliseconds(since: start),
            launch: configuration.launch,
            initialize: initialize,
            checks: checks,
            stderrTail: (configuration.includeStderr || !success) ? stderr : nil
        )
    }

    private func runTool(_ tool: SmokeTool, client: Client) async -> SmokeCheckResult {
        do {
            switch tool {
            case .validate:
                return try await runValidate(client: client)
            case .generate:
                return try await runGenerate(client: client)
            case .explain:
                return try await runExplain(client: client)
            case .inspect:
                return try await runInspect(client: client)
            case .whatDependsOn:
                return try await runWhatDependsOn(client: client)
            case .listBlueprints:
                return try await runListBlueprints(client: client)
            case .schemaInMarkdown:
                return try await runSchemaInMarkdown(client: client)
            }
        } catch {
            return SmokeCheckResult(
                name: tool.rawValue,
                passed: false,
                details: nil,
                error: error.localizedDescription
            )
        }
    }

    private func runValidate(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .validate,
            arguments: ["content": .string(configuration.invalidModelContent)]
        )

        let payload: ValidationPayload = try decodeStructuredContent(result, tool: .validate)
        let codes = payload.diagnostics.compactMap(\.code)

        var failures: [String] = []
        if payload.valid {
            failures.append("Expected `valid` to be false.")
        }
        for code in configuration.expectations.expectedDiagnosticCodes where !codes.contains(code) {
            failures.append("Expected diagnostic code `\(code)`.")
        }

        return SmokeCheckResult(
            name: SmokeTool.validate.rawValue,
            passed: failures.isEmpty,
            details: .object([
                "valid": .bool(payload.valid),
                "diagnosticCodes": .array(codes.map(Value.string)),
                "diagnosticCount": .int(payload.diagnostics.count),
            ]),
            error: failures.isEmpty ? nil : failures.joined(separator: " ")
        )
    }

    private func runExplain(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .explain,
            arguments: ["content": .string(configuration.validModelContent)]
        )

        let payload: ExplanationPayload = try decodeStructuredContent(result, tool: .explain)

        var failures: [String] = []
        if let expectedEntityCount = configuration.expectations.expectedEntityCount,
            payload.summary.entityCount != expectedEntityCount
        {
            failures.append("Expected entityCount=\(expectedEntityCount), got \(payload.summary.entityCount).")
        }

        return SmokeCheckResult(
            name: SmokeTool.explain.rawValue,
            passed: failures.isEmpty,
            details: .object([
                "entityCount": .int(payload.summary.entityCount),
                "containerCount": .int(payload.summary.containerCount),
                "apiCount": .int(payload.summary.apiCount),
            ]),
            error: failures.isEmpty ? nil : failures.joined(separator: " ")
        )
    }

    private func runInspect(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .inspect,
            arguments: [
                "content": .string(configuration.validModelContent),
                "entity": .string(configuration.entity),
            ]
        )

        let payload: InspectionPayload = try decodeStructuredContent(result, tool: .inspect)
        let references = payload.references.map(\.entityName)

        let missingReferences = configuration.expectations.expectedReferences.filter { !references.contains($0) }

        return SmokeCheckResult(
            name: SmokeTool.inspect.rawValue,
            passed: missingReferences.isEmpty,
            details: .object([
                "entityFound": .bool(payload.entity != nil),
                "references": .array(references.map(Value.string)),
                "generatedArtifacts": .array(payload.generatedArtifacts.map(Value.string)),
            ]),
            error: missingReferences.isEmpty ? nil : "Missing expected references: \(missingReferences.joined(separator: ", "))"
        )
    }

    private func runWhatDependsOn(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .whatDependsOn,
            arguments: [
                "content": .string(configuration.validModelContent),
                "entity": .string(configuration.entity),
            ]
        )

        let payload: DependencyPayload = try decodeStructuredContent(result, tool: .whatDependsOn)
        let dependents = payload.dependents.map(\.entityName)
        let missingDependents = configuration.expectations.expectedDependents.filter { !dependents.contains($0) }

        return SmokeCheckResult(
            name: SmokeTool.whatDependsOn.rawValue,
            passed: missingDependents.isEmpty,
            details: .object([
                "entity": .string(payload.entity),
                "dependents": .array(dependents.map(Value.string)),
            ]),
            error: missingDependents.isEmpty ? nil : "Missing expected dependents: \(missingDependents.joined(separator: ", "))"
        )
    }

    private func runListBlueprints(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .listBlueprints,
            arguments: nil
        )

        let payload: BlueprintListPayload = try decodeStructuredContent(result, tool: .listBlueprints)
        let names = payload.blueprints.map(\.name)
        let missingBlueprints = configuration.expectations.expectedBlueprints.filter { !names.contains($0) }

        return SmokeCheckResult(
            name: SmokeTool.listBlueprints.rawValue,
            passed: missingBlueprints.isEmpty,
            details: .object([
                "blueprints": .array(names.map(Value.string)),
            ]),
            error: missingBlueprints.isEmpty ? nil : "Missing expected blueprints: \(missingBlueprints.joined(separator: ", "))"
        )
    }

    private func runSchemaInMarkdown(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .schemaInMarkdown,
            arguments: nil
        )

        let payload: SchemaMarkdownPayload = try decodeStructuredContent(result, tool: .schemaInMarkdown)
        if payload.modelHikeDSL.isEmpty || payload.codeLogicDSL.isEmpty || payload.templateSoupDSL.isEmpty {
            return SmokeCheckResult(
                name: SmokeTool.schemaInMarkdown.rawValue,
                passed: false,
                details: nil,
                error: "Schema markdown payload missing one or more DSL documents."
            )
        }

        return SmokeCheckResult(
            name: SmokeTool.schemaInMarkdown.rawValue,
            passed: true,
            details: .object([
                "modelHikeChars": .int(payload.modelHikeDSL.count),
                "codeLogicChars": .int(payload.codeLogicDSL.count),
                "templateSoupChars": .int(payload.templateSoupDSL.count),
            ]),
            error: nil
        )
    }

    private func runGenerate(client: Client) async throws -> SmokeCheckResult {
        let result = try await callTool(
            client: client,
            name: .generate,
            arguments: [
                "content": .string(configuration.validModelContent),
                "blueprint": .string(configuration.blueprint),
            ]
        )

        let payload: GenerationPayload = try decodeStructuredContent(result, tool: .generate)
        let paths = payload.files.map(\.path)
        let missingSuffixes = configuration.expectations.expectedGeneratedSuffixes.filter { suffix in
            !paths.contains(where: { $0.hasSuffix(suffix) })
        }

        return SmokeCheckResult(
            name: SmokeTool.generate.rawValue,
            passed: missingSuffixes.isEmpty && !paths.isEmpty,
            details: .object([
                "fileCount": .int(payload.summary.fileCount),
                "samplePaths": .array(Array(paths.prefix(10)).map(Value.string)),
            ]),
            error: !paths.isEmpty
                ? (missingSuffixes.isEmpty ? nil : "Missing generated paths matching: \(missingSuffixes.joined(separator: ", "))")
                : "No files were generated."
        )
    }

    private func callTool(
        client: Client,
        name: SmokeTool,
        arguments: [String: Value]?
    ) async throws -> CallTool.Result {
        let request = CallTool.request(.init(name: name.rawValue, arguments: arguments))
        let context = try await client.send(request)
        let result = try await withTimeout(name.rawValue, seconds: configuration.timeoutSeconds) {
            try await context.value
        }

        if result.isError == true {
            throw MCPTesterError.toolFailed(name.rawValue, message: extractText(from: result.content))
        }

        return result
    }

    private func decodeStructuredContent<T: Decodable>(
        _ result: CallTool.Result,
        tool: SmokeTool
    ) throws -> T {
        guard let structuredContent = result.structuredContent else {
            throw MCPTesterError.missingStructuredContent(tool.rawValue)
        }

        let data = try JSONEncoder().encode(structuredContent)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func extractText(from content: [Tool.Content]) -> String {
        let texts = content.compactMap { item -> String? in
            if case let .text(text, _, _) = item {
                return text
            }
            return nil
        }
        return texts.joined(separator: "\n")
    }

    private func decorate(_ message: String, stderr: String?) -> String {
        guard let stderr, !stderr.isEmpty else { return message }
        return "\(message)\n\nstderr:\n\(stderr)"
    }

    private func nonEmptyStderr(from transport: ChildProcessTransport) async -> String? {
        let stderr = await transport.stderrTail()
        return stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : stderr
    }
    private func elapsedMilliseconds(since start: Date) -> Int {
        Int(Date().timeIntervalSince(start) * 1000)
    }
}

private struct ValidationPayload: Decodable {
    let valid: Bool
    let diagnostics: [DiagnosticPayload]
}

private struct DiagnosticPayload: Decodable {
    let code: String?
}

private struct ExplanationPayload: Decodable {
    let summary: ExplanationSummaryPayload
}

private struct ExplanationSummaryPayload: Decodable {
    let containerCount: Int
    let entityCount: Int
    let apiCount: Int
}

private struct InspectionPayload: Decodable {
    let entity: InspectedEntityPayload?
    let references: [ReferencePayload]
    let generatedArtifacts: [String]
}

private struct InspectedEntityPayload: Decodable {
    let name: String
}

private struct ReferencePayload: Decodable {
    let entityName: String
}

private struct DependencyPayload: Decodable {
    let entity: String
    let dependents: [DependentPayload]
}

private struct DependentPayload: Decodable {
    let entityName: String
}

private struct BlueprintListPayload: Decodable {
    let blueprints: [BlueprintPayload]
}

private struct BlueprintPayload: Decodable {
    let name: String
}

private struct GenerationPayload: Decodable {
    let files: [GeneratedFilePayload]
    let summary: GenerationSummaryPayload
}

private struct GeneratedFilePayload: Decodable {
    let path: String
}

private struct GenerationSummaryPayload: Decodable {
    let fileCount: Int
}

private struct SchemaMarkdownPayload: Decodable {
    let modelHikeDSL: String
    let codeLogicDSL: String
    let templateSoupDSL: String
}

private func withTimeout<T: Sendable>(
    _ label: String,
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanoseconds)
            throw MCPTesterError.timeout(label, seconds: seconds)
        }

        let value = try await group.next()!
        group.cancelAll()
        return value
    }
}
