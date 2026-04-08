import ArgumentParser
import Foundation
import MCP

@main
struct DevTester_MCP: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "DevTester_MCP",
        abstract: "Run configurable end-to-end smoke tests against modelhike-mcp.",
        discussion: """
        By default this launches this repo's `modelhike-mcp` target with:
          swift run --package-path <repo-root> modelhike-mcp

        Override the server binary, blueprints path, model fixtures, tool subset, and
        expectation knobs to exercise local MCP changes without editing the tester.
        """
    )

    @Option(name: .long, help: "Path to the main repo root that contains the modelhike-smart-cli Package.swift.")
    var repoRoot: String = DefaultPaths.repoRoot.path

    @Option(name: .long, help: "Path to a prebuilt modelhike-mcp binary. If omitted, the tester uses swift run against the repo root.")
    var serverBinary: String?

    @Option(name: .long, help: "Extra argument to pass through to modelhike-mcp. Repeat as needed.")
    var serverArg: [String] = []

    @Option(name: .long, help: "Optional path passed through as --blueprints to modelhike-mcp.")
    var blueprints: String?

    @Option(name: .long, help: "Blueprint name used for modelhike/generate.")
    var blueprint: String = DefaultModels.blueprint

    @Option(name: .long, help: "Entity name used for inspect and what-depends-on.")
    var entity: String = DefaultModels.entity

    @Option(name: .long, help: "Path to a valid .modelhike file. Defaults to the package's built-in smoke model.")
    var validModelFile: String?

    @Option(name: .long, help: "Path to an invalid .modelhike file. Defaults to the package's built-in W301 smoke model.")
    var invalidModelFile: String?

    @Option(name: .long, help: "Run only the specified tool. Repeat to run multiple tools.")
    var tool: [SmokeToolArgument] = []

    @Option(name: .long, help: "Per-request timeout in seconds.")
    var timeout: Double = 120

    @Option(name: .long, help: "Pretty or JSON output.")
    var output: OutputFormat = .pretty

    @Flag(name: .long, help: "Include server stderr in successful summaries too.")
    var includeStderr = false

    @Flag(name: .long, help: "Show full per-check detail blocks in pretty output.")
    var verbose = false

    @Option(name: .long, help: "Expected diagnostic code from the invalid model. Repeat to assert multiple codes.")
    var expectDiagnosticCode: [String] = []

    @Option(name: .long, help: "Expected entity count from modelhike/explain.")
    var expectEntityCount: Int?

    @Option(name: .long, help: "Expected reference entity name from modelhike/inspect. Repeat to assert multiple references.")
    var expectReference: [String] = []

    @Option(name: .long, help: "Expected dependent entity name from modelhike/what-depends-on. Repeat to assert multiple dependents.")
    var expectDependent: [String] = []

    @Option(name: .long, help: "Expected generated file suffix from modelhike/generate. Repeat to assert multiple paths.")
    var expectGeneratedSuffix: [String] = []

    mutating func run() async throws {
        let configuration = try makeConfiguration()
        let summary = await SmokeRunner(configuration: configuration).run()

        switch output {
        case .pretty:
            print(summary.prettyDescription(verbose: verbose))
        case .json:
            print(try summary.jsonDescription())
        }

        if !summary.success {
            throw ExitCode.failure
        }
    }

    private func makeConfiguration() throws -> SmokeRunConfiguration {
        let repoRootURL = try resolvePath(repoRoot, isDirectory: true)
        guard FileManager.default.fileExists(atPath: repoRootURL.appendingPathComponent("Package.swift").path) else {
            throw ValidationError("`--repo-root` must point at the modelhike-smart-cli repo root.")
        }

        let validModelContent = try validModelFile.map(loadFile) ?? DefaultModels.valid
        let invalidModelContent = try invalidModelFile.map(loadFile) ?? DefaultModels.invalid

        let selectedTools = tool.isEmpty ? SmokeTool.allCases : tool.map(\.tool)

        let usingDefaultValidModel = validModelFile == nil
        let usingDefaultInvalidModel = invalidModelFile == nil

        let expectations = SmokeExpectations(
            expectedAdvertisedTools: Set(SmokeTool.allCases.map(\.rawValue)),
            expectedDiagnosticCodes: !expectDiagnosticCode.isEmpty
                ? expectDiagnosticCode
                : (usingDefaultInvalidModel ? ["W301"] : []),
            expectedEntityCount: expectEntityCount ?? defaultExpectedEntityCount(usingDefaultValidModel: usingDefaultValidModel),
            expectedReferences: !expectReference.isEmpty
                ? expectReference
                : defaultExpectedReferences(usingDefaultValidModel: usingDefaultValidModel),
            expectedDependents: !expectDependent.isEmpty
                ? expectDependent
                : defaultExpectedDependents(usingDefaultValidModel: usingDefaultValidModel),
            expectedBlueprints: DefaultModels.expectedBlueprints,
            expectedGeneratedSuffixes: !expectGeneratedSuffix.isEmpty
                ? expectGeneratedSuffix
                : defaultGeneratedSuffixes(usingDefaultValidModel: usingDefaultValidModel)
        )

        return SmokeRunConfiguration(
            launch: try makeLaunchConfiguration(repoRootURL: repoRootURL),
            timeoutSeconds: timeout,
            blueprint: blueprint,
            entity: entity,
            validModelContent: validModelContent,
            invalidModelContent: invalidModelContent,
            selectedTools: selectedTools,
            expectations: expectations,
            verbose: verbose,
            includeStderr: includeStderr
        )
    }

    private func makeLaunchConfiguration(repoRootURL: URL) throws -> ChildProcessLaunchConfiguration {
        var arguments = serverArg
        if let blueprints {
            arguments.append(contentsOf: ["--blueprints", try resolvePath(blueprints, isDirectory: true).path])
        }

        if let serverBinary {
            let binaryURL = try resolvePath(serverBinary, isDirectory: false)
            return ChildProcessLaunchConfiguration(
                executablePath: binaryURL.path,
                arguments: arguments,
                workingDirectory: repoRootURL.path,
                environment: ProcessInfo.processInfo.environment
            )
        }

        return ChildProcessLaunchConfiguration(
            executablePath: "/usr/bin/env",
            arguments: ["swift", "run", "--package-path", repoRootURL.path, "modelhike-mcp"] + arguments,
            workingDirectory: repoRootURL.path,
            environment: ProcessInfo.processInfo.environment
        )
    }

    private func defaultExpectedEntityCount(usingDefaultValidModel: Bool) -> Int? {
        guard usingDefaultValidModel else { return nil }
        guard entity == DefaultModels.entity else { return nil }
        return DefaultModels.expectedEntityCount
    }

    private func defaultExpectedReferences(usingDefaultValidModel: Bool) -> [String] {
        guard usingDefaultValidModel else { return [] }
        guard entity == DefaultModels.entity else { return [] }
        return DefaultModels.expectedReferences
    }

    private func defaultExpectedDependents(usingDefaultValidModel: Bool) -> [String] {
        guard usingDefaultValidModel else { return [] }
        guard entity == DefaultModels.entity else { return [] }
        return DefaultModels.expectedDependents
    }

    private func defaultGeneratedSuffixes(usingDefaultValidModel: Bool) -> [String] {
        guard usingDefaultValidModel else { return [] }
        guard blueprint == DefaultModels.blueprint else { return [] }
        return DefaultModels.expectedGeneratedSuffixes
    }

    private func loadFile(at path: String) throws -> String {
        let url = try resolvePath(path, isDirectory: false)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func resolvePath(_ path: String, isDirectory: Bool) throws -> URL {
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path, isDirectory: isDirectory)
        }

        let base = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        return base.appendingPathComponent(path, isDirectory: isDirectory)
    }
}

enum SmokeToolArgument: String, ExpressibleByArgument {
    case validate = "modelhike/validate"
    case generate = "modelhike/generate"
    case explain = "modelhike/explain"
    case inspect = "modelhike/inspect"
    case whatDependsOn = "modelhike/what-depends-on"
    case listBlueprints = "modelhike/list-blueprints"
    case schemaInMarkdown = "modelhike/schema-in-markdown"

    var tool: SmokeTool {
        switch self {
        case .validate:
            return .validate
        case .generate:
            return .generate
        case .explain:
            return .explain
        case .inspect:
            return .inspect
        case .whatDependsOn:
            return .whatDependsOn
        case .listBlueprints:
            return .listBlueprints
        case .schemaInMarkdown:
            return .schemaInMarkdown
        }
    }
}

enum OutputFormat: String, ExpressibleByArgument {
    case pretty
    case json
}

enum MCPTesterError: LocalizedError {
    case timeout(String, seconds: Double)
    case missingStructuredContent(String)
    case toolFailed(String, message: String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case let .timeout(label, seconds):
            return "Timed out waiting for \(label) after \(seconds)s."
        case let .missingStructuredContent(tool):
            return "Tool `\(tool)` returned no structuredContent."
        case let .toolFailed(tool, message):
            return message.isEmpty
                ? "Tool `\(tool)` returned isError=true."
                : "Tool `\(tool)` returned isError=true: \(message)"
        case let .transport(message):
            return message
        }
    }
}

private enum DefaultModels {
    static let blueprint = "api-nestjs-monorepo"
    static let entity = "Subscription"
    static let expectedEntityCount = 2
    static let expectedReferences = ["Invoice"]
    static let expectedDependents = ["Invoice"]
    static let expectedBlueprints = ["api-nestjs-monorepo", "api-springboot-monorepo"]
    static let expectedGeneratedSuffixes = ["/package.json", "/controller.ts"]

    static let invalid = """
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

    static let valid = """
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

    Invoice
    =======
    * _id: String
    * subscription: Subscription
    - amount: Float
    """
}

private enum DefaultPaths {
    static let repoRoot: URL = {
        let fileManager = FileManager.default
        var candidate = URL(fileURLWithPath: #filePath).deletingLastPathComponent()

        while candidate.path != "/" {
            if fileManager.fileExists(atPath: candidate.appendingPathComponent("Package.swift").path) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }()
}

private extension SmokeSummary {
    func jsonDescription() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }

    func prettyDescription(verbose: Bool) -> String {
        var lines: [String] = []
        lines.append("Launch: \(renderLaunch())")

        if let initialize {
            lines.append("Initialize: \(initialize.serverName) \(initialize.serverVersion) via MCP \(initialize.protocolVersion)")
        } else {
            lines.append("Initialize: failed")
        }

        lines.append("Duration: \(durationMs)ms")

        for check in checks {
            lines.append("\(check.passed ? "PASS" : "FAIL") \(check.name)")

            if let error = check.error {
                lines.append("  \(error)")
            }

            if verbose, let details = check.details {
                lines.append(contentsOf: renderDetails(details).map { "  \($0)" })
            }
        }

        if let stderrTail, !stderrTail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("stderr:")
            lines.append(stderrTail)
        }

        lines.append("Overall: \(success ? "PASS" : "FAIL")")
        return lines.joined(separator: "\n")
    }

    private func renderLaunch() -> String {
        ([launch.executablePath] + launch.arguments).map(shellEscape).joined(separator: " ")
    }

    private func renderDetails(_ value: Value) -> [String] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else {
            return ["<unprintable details>"]
        }
        return String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init)
    }

    private func shellEscape(_ value: String) -> String {
        guard value.contains(where: { $0 == " " || $0 == "\"" }) else {
            return value
        }

        let escaped = value.replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}
