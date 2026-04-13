import Foundation
import ModelHike
import ModelHike_Blueprints

public struct ModelHikeEngine: Sendable {
    private let blueprintsPath: String?

    public init(blueprintsPath: String? = nil) {
        self.blueprintsPath = blueprintsPath
    }

    public func validate(_ input: ModelInput) async throws -> ValidationResult {
        do {
            let run = try await runPipeline(
                for: input,
                pipeline: Pipeline {
                    LoadModelsPass()
                    HydrateModelsPass()
                    PassDownAndProcessAnnotationsPass()
                    ValidateModelsPass()
                }
            )
            let diagnostics = diagnostics(from: run)
            return ValidationResult(valid: diagnostics.isEmpty, diagnostics: diagnostics)
        } catch {
            let diagnostics = DiagnosticExtractor.singleError(error)
            return ValidationResult(valid: false, diagnostics: diagnostics)
        }
    }

    public func dryRun(
        _ input: ModelInput,
        blueprint: String? = nil,
        containers: [String] = [],
        systemViews: [String] = []
    ) async throws -> GenerationResult {
        try await runGeneration(
            input,
            blueprint: blueprint,
            containers: containers,
            systemViews: systemViews,
            outputPath: nil,
            persistOutput: false
        )
    }

    public func generate(
        _ input: ModelInput,
        blueprint: String? = nil,
        containers: [String] = [],
        systemViews: [String] = [],
        outputPath: String? = nil
    ) async throws -> GenerationResult {
        try await runGeneration(
            input,
            blueprint: blueprint,
            containers: containers,
            systemViews: systemViews,
            outputPath: outputPath,
            persistOutput: true
        )
    }

    public func generateInline(
        _ input: ModelInput,
        inlineBlueprint: InlineBlueprintSnapshot,
        containers: [String] = [],
        persist: Bool = false,
        outputPath: String? = nil
    ) async throws -> GenerationResult {
        do {
            let resolvedInput = try resolve(input: input)
            let inlineArtifacts = makeInlineArtifacts(from: resolvedInput)
            guard inlineBlueprint.files[""]?["main.ss"] != nil else {
                throw EngineError.inlineBlueprintMissingMainScript
            }
            let filesByPath: [String: String]
            let outputDirectory: String?

            if persist {
                let run = try await InlineGenerationHarness.generateToTempFolder(
                    model: inlineArtifacts.model,
                    commonTypes: inlineArtifacts.commonTypes,
                    config: inlineArtifacts.config,
                    blueprint: inlineBlueprint.toInlineBlueprint(),
                    containersToOutput: containers
                )
                if let outputPath {
                    try persistInlineFiles(run.files, to: outputPath)
                    try? FileManager.default.removeItem(at: run.path.url)
                    filesByPath = run.files
                    outputDirectory = outputPath
                } else {
                    filesByPath = run.files
                    outputDirectory = run.path.string
                }
            } else {
                filesByPath = try await InlineGenerationHarness.generate(
                    model: inlineArtifacts.model,
                    commonTypes: inlineArtifacts.commonTypes,
                    config: inlineArtifacts.config,
                    blueprint: inlineBlueprint.toInlineBlueprint(),
                    containersToOutput: containers
                )
                outputDirectory = nil
            }

            let files = filesByPath.keys.sorted().map {
                GeneratedFile(path: $0, content: filesByPath[$0] ?? "")
            }
            return GenerationResult(
                files: files,
                tree: OutputTreeBuilder.renderTree(for: files.map(\.path)),
                diagnostics: [],
                persisted: persist,
                outputDirectory: outputDirectory
            )
        } catch {
            return GenerationResult(
                files: [],
                tree: "",
                diagnostics: DiagnosticExtractor.singleError(error),
                persisted: false,
                outputDirectory: persist ? outputPath : nil
            )
        }
    }

    private func runGeneration(
        _ input: ModelInput,
        blueprint: String?,
        containers: [String],
        systemViews: [String],
        outputPath: String?,
        persistOutput: Bool
    ) async throws -> GenerationResult {
        // Where the pipeline writes: real disk for `generate` (optional path → else upstream default
        // `<basePath>/modelhike-output`), or a throwaway temp for `dry-run` that we delete afterward.
        let pipelineOutputPath: String?
        var dryRunTempRoot: URL?
        if persistOutput {
            pipelineOutputPath = outputPath
            dryRunTempRoot = nil
        } else {
            let tmp = temporaryOutputURL()
            pipelineOutputPath = tmp.path
            dryRunTempRoot = tmp.deletingLastPathComponent()
        }
        defer {
            if let dryRunTempRoot {
                try? FileManager.default.removeItem(at: dryRunTempRoot)
            }
        }

        do {
            let generationTargets = try resolveGenerationTargets(
                blueprint: blueprint,
                containers: containers,
                systemViews: systemViews
            )
            switch generationTargets.outputItemType {
            case .container:
                break
            case .system:
                throw EngineError.unsupportedGenerationTargetKind("system views")
            }

            let run = try await runPipeline(
                for: input,
                pipeline: Pipeline {
                    LoadModelsPass()
                    HydrateModelsPass()
                    PassDownAndProcessAnnotationsPass()
                    ValidateModelsPass()
                    GenerateCodePass()
                    if persistOutput {
                        Persist.toOutputFolder()
                    }
                },
                outputPath: pipelineOutputPath,
                blueprintName: blueprint,
                generationTargets: generationTargets
            )
            let diagnostics = diagnostics(from: run)
            let outputRoot = run.outputRoot

            if DiagnosticSummary(diagnostics: diagnostics).hasErrors {
                return GenerationResult(
                    files: [],
                    tree: "",
                    diagnostics: diagnostics,
                    persisted: false,
                    outputDirectory: persistOutput ? outputRoot : nil
                )
            }

            let files = mapGeneratedFiles(
                records: await run.pipeline.state.renderedOutputRecords(),
                outputRoot: outputRoot
            )

            return GenerationResult(
                files: files,
                tree: OutputTreeBuilder.renderTree(for: files.map(\.path)),
                diagnostics: diagnostics,
                persisted: persistOutput,
                outputDirectory: persistOutput ? outputRoot : nil
            )
        } catch {
            return GenerationResult(
                files: [],
                tree: "",
                diagnostics: DiagnosticExtractor.singleError(error),
                persisted: false,
                outputDirectory: persistOutput ? (outputPath ?? nil) : nil
            )
        }
    }

    public func explain(_ input: ModelInput) async throws -> ExplanationResult {
        do {
            let run = try await runPipeline(
                for: input,
                pipeline: Pipeline {
                    LoadModelsPass()
                    HydrateModelsPass()
                    PassDownAndProcessAnnotationsPass()
                }
            )
            return SnapshotMapper.map(run.session.model, diagnostics: diagnostics(from: run))
        } catch {
            return ExplanationResult(
                containers: [],
                diagnostics: DiagnosticExtractor.singleError(error),
                summary: ModelSummary(containerCount: 0, moduleCount: 0, entityCount: 0, propertyCount: 0, methodCount: 0, apiCount: 0)
            )
        }
    }

    public func inspect(_ input: ModelInput, entity: String) async throws -> InspectionResult {
        do {
            let explanation = try await explain(input)
            let (match, _, _) = SnapshotMapper.findEntity(named: entity, in: explanation)
            let diagnostics = explanation.diagnostics

            guard let match else {
                var resultDiagnostics = diagnostics
                resultDiagnostics.append(
                    Diagnostic(
                        severity: .error,
                        message: "Entity '\(entity)' was not found in the loaded model."
                    )
                )
                return InspectionResult(entity: nil, references: [], generatedArtifacts: [], diagnostics: resultDiagnostics)
            }

            let references = DependencyWalker.references(to: match, in: explanation)
            let generatedArtifacts = match.apis.map { "\($0.type): \($0.name)" }

            return InspectionResult(
                entity: match,
                references: references,
                generatedArtifacts: generatedArtifacts,
                diagnostics: diagnostics
            )
        } catch {
            return InspectionResult(
                entity: nil,
                references: [],
                generatedArtifacts: [],
                diagnostics: DiagnosticExtractor.singleError(error)
            )
        }
    }

    public func whatDependsOn(_ input: ModelInput, entity: String, changeKind: String? = nil, newName: String? = nil) async throws -> DependencyResult {
        do {
            // Run the pipeline to get both the snapshot (via explain) and the live AppModel
            let run = try await runPipeline(
                for: input,
                pipeline: Pipeline {
                    LoadModelsPass()
                    HydrateModelsPass()
                    PassDownAndProcessAnnotationsPass()
                }
            )
            let explanation = SnapshotMapper.map(run.session.model, diagnostics: diagnostics(from: run))

            // Snapshot-based dependents (types, methods, annotations, tags)
            let snapshotDeps = DependencyWalker.dependents(of: entity, in: explanation)

            // Live AppModel dependents (constraints, expressions, method params)
            let appModel = await run.pipeline.ws.context.model
            let liveDeps = await DependencyWalker.liveModelDependents(of: entity, in: appModel)

            let dependents = DependencyWalker.mergeDependents(snapshotDeps, liveDeps)
            var diagnostics = explanation.diagnostics

            let breakingChanges: [BreakingChange]
            if let changeKind = changeKind {
                breakingChanges = DependencyWalker.computeBreakingChanges(
                    dependents: dependents,
                    changeKind: changeKind,
                    oldName: entity,
                    newName: newName
                )
            } else {
                breakingChanges = []
            }

            if dependents.isEmpty && changeKind == nil {
                diagnostics.append(
                    Diagnostic(
                        severity: .info,
                        message: "No dependents found for '\(entity)'."
                    )
                )
            }

            return DependencyResult(entity: entity, dependents: dependents, breakingChanges: breakingChanges, diagnostics: diagnostics)
        } catch {
            return DependencyResult(entity: entity, dependents: [], breakingChanges: [], diagnostics: DiagnosticExtractor.singleError(error))
        }
    }

    public func listBlueprints() async throws -> BlueprintListResult {
        var config = PipelineConfig()
        config.flags.printDiagnosticsToStdout = false
        config.flags.pipelineProgressToStdout = false
        config.basePath = LocalPath(FileManager.default.currentDirectoryPath)
        configureBlueprintSources(in: &config)

        let aggregator = BlueprintAggregator(config: config)
        let blueprints = Array(Set(await aggregator.availableBlueprints)).sorted().map(BlueprintInfo.init)
        return BlueprintListResult(blueprints: blueprints, diagnostics: [])
    }

    public func listTypes(_ input: ModelInput) async throws -> TypeListResult {
        do {
            let explanation = try await explain(input)
            var types: [TypeInfo] = []

            for container in explanation.containers {
                collectTypes(in: container.modules, container: container.displayName, into: &types)
            }

            types.sort { ($0.container, $0.module, $0.name) < ($1.container, $1.module, $1.name) }

            return TypeListResult(types: types, diagnostics: explanation.diagnostics)
        } catch {
            return TypeListResult(types: [], diagnostics: DiagnosticExtractor.singleError(error))
        }
    }

    private func collectTypes(in modules: [ModuleSummary], container: String, into: inout [TypeInfo]) {
        for module in modules {
            for object in module.objects {
                into.append(
                    TypeInfo(
                        name: object.displayName,
                        kind: object.kind,
                        module: module.displayName,
                        container: container
                    )
                )
            }
            collectTypes(in: module.submodules, container: container, into: &into)
        }
    }

    public func fix(_ input: ModelInput, codes: [String]? = nil) async throws -> FixResult {
        // Get the original model content (sync)
        let originalContent: String
        switch input {
        case .content(let content):
            originalContent = content
        case .file(let path):
            originalContent = try String(contentsOfFile: path, encoding: .utf8)
        case .directory:
            // Directory input not supported for fix (need single file)
            return FixResult(
                fixed: false,
                model: nil,
                applied: [],
                remaining: [],
                diagnostics: [Diagnostic(
                    severity: .error,
                    message: "fix command requires single file or stdin input, not directory"
                )]
            )
        }

        do {
            let validationResult = try await validate(input)
            let allDiagnostics = validationResult.diagnostics

            // Filter by codes if provided
            var filteredDiagnostics: [Diagnostic] = []
            if let filterCodes = codes, !filterCodes.isEmpty {
                let normalizedCodes = Set(filterCodes)
                for diag in allDiagnostics {
                    if let code = diag.code, normalizedCodes.contains(code.rawValue) {
                        filteredDiagnostics.append(diag)
                    }
                }
            } else {
                filteredDiagnostics = allDiagnostics
            }

            let (pendingFixes, unfixable) = collectFixes(for: filteredDiagnostics, in: originalContent)
            let (modifiedContent, appliedActions) = applyFixes(pendingFixes, to: originalContent)

            return FixResult(
                fixed: unfixable.isEmpty && !appliedActions.isEmpty,
                model: !appliedActions.isEmpty ? modifiedContent : originalContent,
                applied: appliedActions,
                remaining: unfixable,
                diagnostics: validationResult.diagnostics
            )
        } catch {
            return FixResult(
                fixed: false,
                model: nil,
                applied: [],
                remaining: [],
                diagnostics: DiagnosticExtractor.singleError(error)
            )
        }
    }

    private struct PendingFix {
        let lineNo: Int
        let action: FixAction
        let apply: (inout [String], Int) -> Bool // transforms the line
    }

    private func collectFixes(for diagnostics: [Diagnostic], in content: String) -> ([PendingFix], [Diagnostic]) {
        var fixes: [PendingFix] = []
        var unfixable: [Diagnostic] = []

        for diagnostic in diagnostics {
            guard let code = diagnostic.code, let source = diagnostic.source else {
                unfixable.append(diagnostic)
                continue
            }

            switch code {
            case .w301:
                // Extract the unresolved type name from lineContent (e.g. "* owner: CustomerProfile")
                guard let unresolvedType = extractUnresolvedTypeName(from: source.lineContent) else {
                    unfixable.append(diagnostic)
                    continue
                }

                // Look for didYouMean first, then availableOptions with exactly one option
                var replacement: String?
                for suggestion in diagnostic.suggestions {
                    if suggestion.kind == .didYouMean {
                        replacement = suggestion.replacement ?? suggestion.options.first
                        break
                    }
                }
                if replacement == nil {
                    for suggestion in diagnostic.suggestions {
                        if suggestion.kind == .availableOptions, suggestion.options.count == 1 {
                            replacement = suggestion.options.first
                            break
                        }
                    }
                }

                guard let resolvedType = replacement else {
                    unfixable.append(diagnostic)
                    continue
                }

                let capturedUnresolved = unresolvedType
                let capturedResolved = resolvedType
                fixes.append(PendingFix(
                    lineNo: source.lineNo,
                    action: FixAction(
                        code: code,
                        message: diagnostic.message,
                        action: "Replaced '\(capturedUnresolved)' with '\(capturedResolved)'",
                        line: source.lineNo
                    ),
                    apply: { lines, lineIndex in
                        let before = lines[lineIndex]
                        let after = before.replacingOccurrences(of: capturedUnresolved, with: capturedResolved)
                        guard after != before else { return false }
                        lines[lineIndex] = after
                        return true
                    }
                ))

            case .e618:
                guard diagnostic.message.contains("Insert a blank line before") else {
                    unfixable.append(diagnostic)
                    continue
                }

                fixes.append(PendingFix(
                    lineNo: source.lineNo,
                    action: FixAction(
                        code: code,
                        message: diagnostic.message,
                        action: "Inserted blank line before line \(source.lineNo)",
                        line: source.lineNo
                    ),
                    apply: { lines, lineIndex in
                        if lineIndex > 0, lines[lineIndex - 1].trimmingCharacters(in: .whitespaces).isEmpty {
                            return false
                        }
                        lines.insert("", at: lineIndex)
                        return true
                    }
                ))

            default:
                unfixable.append(diagnostic)
            }
        }

        return (fixes, unfixable)
    }

    private func applyFixes(_ fixes: [PendingFix], to content: String) -> (String, [FixAction]) {
        guard !fixes.isEmpty else { return (content, []) }

        var lines = content.components(separatedBy: "\n")
        var applied: [FixAction] = []

        // Index fixes by line number; process in reverse order so line numbers stay stable
        var fixesByLine: [Int: [PendingFix]] = [:]
        for fix in fixes {
            fixesByLine[fix.lineNo, default: []].append(fix)
        }

        for lineNo in fixesByLine.keys.sorted(by: >) {
            let lineIndex = lineNo - 1
            guard lineIndex >= 0, lineIndex <= lines.count else { continue }

            if let lineFixes = fixesByLine[lineNo] {
                for fix in lineFixes {
                    if fix.apply(&lines, lineIndex) {
                        applied.append(fix.action)
                    }
                }
            }
        }

        return (lines.joined(separator: "\n"), applied)
    }

    private func extractUnresolvedTypeName(from lineContent: String) -> String? {
        // DSL property lines look like: "* fieldName: TypeName" or "- fieldName: TypeName[1..*]"
        // Also handles "* fieldName: TypeName@Target"
        let trimmed = lineContent.trimmingCharacters(in: .whitespaces)
        guard let colonIndex = trimmed.firstIndex(of: ":") else { return nil }
        var typePart = String(trimmed[trimmed.index(after: colonIndex)...])
            .trimmingCharacters(in: .whitespaces)

        // Strip cardinality suffix like [1..*]
        if let bracketIndex = typePart.firstIndex(of: "[") {
            typePart = String(typePart[..<bracketIndex])
        }

        // Strip @Target suffix
        if let atIndex = typePart.firstIndex(of: "@") {
            typePart = String(typePart[..<atIndex])
        }

        // Strip annotation suffix like (backend)
        if let parenIndex = typePart.firstIndex(of: "(") {
            typePart = String(typePart[..<parenIndex])
        }

        typePart = typePart.trimmingCharacters(in: .whitespaces)
        return typePart.isEmpty ? nil : typePart
    }

    /// Canonical DSL prose bundled as markdown (from upstream `ModelHikeDSLSchema.bundled`).
    public func dslSchemaMarkdown() -> ModelHikeDSLSchema? {
        ModelHikeDSLSchema.bundled
    }

    public func preflight(_ input: ModelInput, blueprint: String? = nil) async throws -> PreflightResult {
        let modelContent = input.modelContent

        do {
            var checks: [PreflightCheck] = []

                // Check 1: syntax valid
                let validationResult = try await validate(input)
                var hasSyntaxErrors = false
                for diag in validationResult.diagnostics {
                    if diag.severity == .error {
                        hasSyntaxErrors = true
                        break
                    }
                }
                checks.append(
                    PreflightCheck(
                        name: "syntax_valid",
                        status: hasSyntaxErrors ? "fail" : "pass",
                        detail: hasSyntaxErrors ? "Model has parse/syntax errors" : "Model parses successfully",
                        fixHint: hasSyntaxErrors ? "Fix syntax errors shown in diagnostics" : ""
                    )
                )

                // Check 2: types resolved (W301)
                var hasUnresolvedTypes = false
                for diag in validationResult.diagnostics {
                    if diag.code == .w301 {
                        hasUnresolvedTypes = true
                        break
                    }
                }
                checks.append(
                    PreflightCheck(
                        name: "types_resolved",
                        status: hasUnresolvedTypes ? "fail" : "pass",
                        detail: hasUnresolvedTypes ? "Unresolved type references (W301)" : "All types resolved",
                        fixHint: hasUnresolvedTypes ? "Use `fix` command or `list-types` to see available types" : ""
                    )
                )

                // Check 3: references resolved (W302)
                var hasUnresolvedRefs = false
                for diag in validationResult.diagnostics {
                    if diag.code == .w302 {
                        hasUnresolvedRefs = true
                        break
                    }
                }
                checks.append(
                    PreflightCheck(
                        name: "references_resolved",
                        status: hasUnresolvedRefs ? "fail" : "pass",
                        detail: hasUnresolvedRefs ? "Unresolved constraint references (W302)" : "All constraints resolved",
                        fixHint: hasUnresolvedRefs ? "Review constraint expressions (@...) in model" : ""
                    )
                )

                // Check 4: no duplicates (W304-W306)
                var hasDuplicates = false
                for diag in validationResult.diagnostics {
                    if let code = diag.code, [.w304, .w305, .w306].contains(code) {
                        hasDuplicates = true
                        break
                    }
                }
                checks.append(
                    PreflightCheck(
                        name: "no_duplicates",
                        status: hasDuplicates ? "warn" : "pass",
                        detail: hasDuplicates ? "Duplicate type/property/method names detected" : "No duplicate names",
                        fixHint: hasDuplicates ? "Review and resolve duplicate names in entities" : ""
                    )
                )

                // Check 5: module references (W303)
                var hasUnresolvedModules = false
                for diag in validationResult.diagnostics {
                    if diag.code == .w303 {
                        hasUnresolvedModules = true
                        break
                    }
                }
                checks.append(
                    PreflightCheck(
                        name: "modules_resolved",
                        status: hasUnresolvedModules ? "fail" : "pass",
                        detail: hasUnresolvedModules ? "Unresolved module references (W303)" : "All module references resolved",
                        fixHint: hasUnresolvedModules ? "Check `+ ModuleName` references match defined modules" : ""
                    )
                )

                // Check 6: blueprints available
                let availableBlueprints = (try await listBlueprints()).blueprints.map { $0.name }
                checks.append(
                    PreflightCheck(
                        name: "blueprints_available",
                        status: availableBlueprints.count > 0 ? "pass" : "warn",
                        detail: availableBlueprints.isEmpty
                            ? "No blueprints available"
                            : "Blueprints available: \(availableBlueprints.joined(separator: ", "))",
                        fixHint: availableBlueprints.isEmpty ? "Install blueprints or use --blueprints flag" : ""
                    )
                )

                // Check 7: blueprint tags assigned to containers
                if let overrideBlueprint = blueprint {
                    let isValid = availableBlueprints.contains(overrideBlueprint)
                    checks.append(
                        PreflightCheck(
                            name: "blueprints_assigned",
                            status: isValid ? "pass" : "fail",
                            detail: isValid
                                ? "Blueprint override '\(overrideBlueprint)' is valid"
                                : "Blueprint '\(overrideBlueprint)' not found in available blueprints",
                            fixHint: isValid ? "" : "Available: \(availableBlueprints.joined(separator: ", "))"
                        )
                    )
                } else {
                    let explanation = try await explain(input)
                    let containerNames = explanation.containers.map { $0.displayName }

                    if containerNames.isEmpty {
                        checks.append(
                            PreflightCheck(
                                name: "blueprints_assigned",
                                status: "fail",
                                detail: "No containers found in model",
                                fixHint: "Define at least one container using === ContainerName ===="
                            )
                        )
                    } else {
                        let taggedContainers = parseBlueprintTags(from: modelContent)
                        var untagged: [String] = []
                        for name in containerNames {
                            if taggedContainers[name] == nil {
                                untagged.append(name)
                            }
                        }

                        if untagged.isEmpty {
                            var details: [String] = []
                            for name in containerNames {
                                if let bp = taggedContainers[name] {
                                    details.append("\(name) → \(bp)")
                                }
                            }
                            let invalidBlueprints = taggedContainers.values.filter { !availableBlueprints.contains($0) }
                            if !invalidBlueprints.isEmpty {
                                checks.append(
                                    PreflightCheck(
                                        name: "blueprints_assigned",
                                        status: "fail",
                                        detail: "Unknown blueprint(s): \(invalidBlueprints.joined(separator: ", ")). Assigned: \(details.joined(separator: "; "))",
                                        fixHint: "Available: \(availableBlueprints.joined(separator: ", "))"
                                    )
                                )
                            } else {
                                checks.append(
                                    PreflightCheck(
                                        name: "blueprints_assigned",
                                        status: "pass",
                                        detail: details.joined(separator: "; "),
                                        fixHint: ""
                                    )
                                )
                            }
                        } else {
                            checks.append(
                                PreflightCheck(
                                    name: "blueprints_assigned",
                                    status: "fail",
                                    detail: "Containers missing #blueprint(...) tag: \(untagged.joined(separator: ", "))",
                                    fixHint: "Add #blueprint(name) inside each container block, or use --blueprint flag"
                                )
                            )
                        }
                    }
                }

                var anyFail = false
                var anyWarn = false
                for check in checks {
                    if check.status == "fail" { anyFail = true }
                    if check.status == "warn" { anyWarn = true }
                }
                let ready = !anyFail
                let recommendation: String
                if anyFail {
                    recommendation = "Fix failing checks before generation"
                } else if anyWarn {
                    recommendation = "Ready to generate (with warnings)"
                } else {
                    recommendation = "Ready to generate"
                }

            return PreflightResult(
                ready: ready,
                checks: checks,
                recommendation: recommendation,
                diagnostics: validationResult.diagnostics
            )
        } catch {
            return PreflightResult(
                ready: false,
                checks: [],
                recommendation: "Error during preflight check",
                diagnostics: DiagnosticExtractor.singleError(error)
            )
        }
    }

    /// Parses `#blueprint(name)` tags from raw model text, returning a map of container name → blueprint name.
    private func parseBlueprintTags(from content: String?) -> [String: String] {
        guard let content = content else { return [:] }
        var result: [String: String] = [:]
        var currentContainerName: String?
        let lines = content.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            // Container start fence: a line that is only "===" (3+ equals, no other text)
            if line.allSatisfy({ $0 == "=" }) && line.count >= 3 {
                // Next non-empty line is the container name
                let nameIndex = i + 1
                if nameIndex < lines.count {
                    let name = lines[nameIndex].trimmingCharacters(in: .whitespaces)
                    // Followed by end fence "====" (4+ equals)
                    let fenceIndex = nameIndex + 1
                    if fenceIndex < lines.count {
                        let fence = lines[fenceIndex].trimmingCharacters(in: .whitespaces)
                        if fence.allSatisfy({ $0 == "=" }) && fence.count >= 4 {
                            currentContainerName = name
                            i = fenceIndex + 1
                            continue
                        }
                    }
                }
            }

            // Look for #blueprint(...) tag within the current container block
            if let containerName = currentContainerName, line.hasPrefix("#blueprint(") {
                let start = line.index(line.startIndex, offsetBy: 11)
                if let end = line.firstIndex(of: ")") {
                    let blueprintName = String(line[start..<end]).trimmingCharacters(in: .whitespaces)
                    if !blueprintName.isEmpty {
                        result[containerName] = blueprintName
                    }
                }
            }

            // Module definition resets container context (=== ModuleName ===)
            if line.hasPrefix("===") && line.hasSuffix("===") && line.count > 6 {
                currentContainerName = nil
            }

            i += 1
        }

        return result
    }

    private func runPipeline(
        for input: ModelInput,
        pipeline: Pipeline,
        outputPath: String? = nil,
        blueprintName: String? = nil,
        generationTargets: GenerationTargets = .allContainers
    ) async throws -> PipelineRun {
        let resolvedInput = try resolve(input: input)
        let recorder = DefaultDebugRecorder()

        var config = PipelineConfig()
        config.flags.printDiagnosticsToStdout = false
        config.flags.pipelineProgressToStdout = false
        config.debugRecorder = recorder
        config.basePath = LocalPath(resolvedInput.basePath)
        if let outputPath {
            config.output = LocalFolder(path: LocalPath(outputPath))
        }
        config.blueprintName = blueprintName
        config.outputItemType = generationTargets.outputItemType
        config.containersToOutput = generationTargets.containers
        config.systemsToOutput = generationTargets.systems
        configureBlueprintSources(in: &config)
        config.modelSource = .inline(await inlineModelLoader(for: resolvedInput, pipeline: pipeline))

        let succeeded = try await pipeline.run(using: config)
        await pipeline.ws.context.debugLog.drainRecorder()
        let session = await recorder.session(config: config)

        return PipelineRun(
            pipeline: pipeline,
            session: session,
            succeeded: succeeded,
            outputRoot: config.output.pathString
        )
    }

    private func inlineModelLoader(for input: ResolvedModelInput, pipeline: Pipeline) async -> InlineModelLoader {
        let context = await pipeline.ws.context
        return InlineModelLoader(with: context) {
            if let inlineConfig = input.inlineConfig {
                InlineConfig(identifier: inlineConfig.identifier) { inlineConfig.content }
            }
            input.commonModels.map { common in
                InlineCommonTypes(identifier: common.identifier) { common.content }
            }
            input.domainModels.map { domain in
                InlineModel(identifier: domain.identifier) { domain.content }
            }
        }
    }

    private func diagnostics(from run: PipelineRun) -> [Diagnostic] {
        let diagnostics = DiagnosticExtractor.extract(from: run.session)
        guard !run.succeeded, diagnostics.isEmpty else {
            return diagnostics
        }
        return DiagnosticExtractor.singleError(EngineError.pipelineFailed)
    }

    private func resolveGenerationTargets(
        blueprint: String?,
        containers: [String],
        systemViews: [String]
    ) throws -> GenerationTargets {
        let nonEmptyKinds = [
            !containers.isEmpty,
            !systemViews.isEmpty,
        ].filter { $0 }.count

        if nonEmptyKinds > 1 {
            throw EngineError.conflictingGenerationTargetKinds
        }

        if blueprint != nil && nonEmptyKinds == 0 {
            throw EngineError.blueprintOverrideRequiresTarget
        }

        if !containers.isEmpty {
            return GenerationTargets(
                outputItemType: .container,
                containers: containers,
                systems: []
            )
        }

        if !systemViews.isEmpty {
            return GenerationTargets(
                outputItemType: .system,
                containers: [],
                systems: systemViews
            )
        }

        return .allContainers
    }

    private func resolve(input: ModelInput) throws -> ResolvedModelInput {
        switch input {
        case .content(let content):
            return ResolvedModelInput(
                domainModels: [NamedTextFile(identifier: "stdin.modelhike", content: content)],
                commonModels: [],
                inlineConfig: nil,
                basePath: FileManager.default.currentDirectoryPath
            )
        case .file(let path):
            return try resolveFileInput(path)
        case .directory(let path):
            return try resolveDirectoryInput(path)
        }
    }

    private func resolveFileInput(_ path: String) throws -> ResolvedModelInput {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw EngineError.inputNotFound(path)
        }

        let directory = url.deletingLastPathComponent()
        let content = try String(contentsOf: url, encoding: .utf8)
        var commonModels: [NamedTextFile] = []
        let commonURL = directory.appendingPathComponent(ModelSupportFiles.commonModelFileName)
        if commonURL.path != url.path, FileManager.default.fileExists(atPath: commonURL.path) {
            commonModels.append(NamedTextFile(identifier: commonURL.lastPathComponent, content: try String(contentsOf: commonURL, encoding: .utf8)))
        }

        let configURL = ModelSupportFiles.configFileURL(in: directory)
        let inlineConfig: NamedTextFile?
        if let configURL {
            inlineConfig = NamedTextFile(identifier: configURL.lastPathComponent, content: try String(contentsOf: configURL, encoding: .utf8))
        } else {
            inlineConfig = nil
        }

        return ResolvedModelInput(
            domainModels: [NamedTextFile(identifier: url.lastPathComponent, content: content)],
            commonModels: commonModels,
            inlineConfig: inlineConfig,
            basePath: directory.path
        )
    }

    private func resolveDirectoryInput(_ path: String) throws -> ResolvedModelInput {
        let url = URL(fileURLWithPath: path)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw EngineError.inputNotFound(path)
        }

        let children = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var domainModels: [NamedTextFile] = []
        var commonModels: [NamedTextFile] = []
        var inlineConfig: NamedTextFile?

        for child in children {
            guard child.hasDirectoryPath == false else { continue }

            if child.lastPathComponent == ModelSupportFiles.commonModelFileName {
                commonModels.append(
                    NamedTextFile(identifier: child.lastPathComponent, content: try String(contentsOf: child, encoding: .utf8))
                )
            } else if ModelSupportFiles.isConfigFileName(child.lastPathComponent) {
                inlineConfig = NamedTextFile(identifier: child.lastPathComponent, content: try String(contentsOf: child, encoding: .utf8))
            } else if child.pathExtension == ModelConstants.ModelFile_Extension {
                domainModels.append(
                    NamedTextFile(identifier: child.lastPathComponent, content: try String(contentsOf: child, encoding: .utf8))
                )
            }
        }

        if domainModels.isEmpty {
            throw EngineError.noModelFiles(url.path)
        }

        return ResolvedModelInput(
            domainModels: domainModels,
            commonModels: commonModels,
            inlineConfig: inlineConfig,
            basePath: url.path
        )
    }

    private func makeInlineArtifacts(from input: ResolvedModelInput) -> (model: InlineModel, commonTypes: InlineCommonTypes?, config: InlineConfig?) {
        let modelIdentifier = input.domainModels.first?.identifier ?? "stdin.modelhike"
        let model = InlineModel(identifier: modelIdentifier) {
            input.domainModels.map(\.content)
        }

        let commonTypes: InlineCommonTypes?
        if input.commonModels.isEmpty {
            commonTypes = nil
        } else {
            let commonIdentifier = input.commonModels.first?.identifier ?? ModelSupportFiles.commonModelFileName
            commonTypes = InlineCommonTypes(identifier: commonIdentifier) {
                input.commonModels.map(\.content)
            }
        }

        let config: InlineConfig?
        if let inlineConfig = input.inlineConfig {
            config = InlineConfig(identifier: inlineConfig.identifier) {
                inlineConfig.content
            }
        } else {
            config = nil
        }

        return (model, commonTypes, config)
    }

    private func persistInlineFiles(_ files: [String: String], to outputPath: String) throws {
        let outputURL = URL(fileURLWithPath: outputPath, isDirectory: true)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        for path in files.keys.sorted() {
            let fileURL = outputURL.appendingPathComponent(path)
            let parent = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            if let content = files[path] {
                try content.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        }
    }

    private func mapGeneratedFiles(
        records: [RenderedOutputRecord],
        outputRoot: String
    ) -> [GeneratedFile] {
        let root = LocalPath(outputRoot)
        return records
            .compactMap { record -> GeneratedFile? in
                guard let relativePath = LocalPath(record.path).relativePath(from: root),
                      !relativePath.isEmpty else { return nil }
                return GeneratedFile(path: relativePath, content: record.content)
            }
            .sorted { $0.path < $1.path }
    }

    private func resolvedBlueprintsPath() -> String? {
        if let blueprintsPath, !blueprintsPath.isEmpty {
            return blueprintsPath
        }
        if let env = ProcessInfo.processInfo.environment["MODELHIKE_BLUEPRINTS"], !env.isEmpty {
            return env
        }
        return nil
    }

    private func configureBlueprintSources(in config: inout PipelineConfig) {
        config.blueprints.append(OfficialBlueprintFinder())
        if let blueprintsPath = resolvedBlueprintsPath() {
            config.localBlueprintsPath = LocalPath(blueprintsPath)
        }
    }

    private func temporaryOutputURL() -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("modelhike-smart-cli-\(UUID().uuidString)", isDirectory: true)
        return root.appendingPathComponent("output", isDirectory: true)
    }
}

enum ModelSupportFiles {
    static let commonModelFileName = TemplateConstants.CommonModelFile + "." + ModelConstants.ModelFile_Extension
    static let preferredConfigFileName = TemplateConstants.MainScriptFile + "." + ModelConstants.ConfigFile_Extension

    static func isConfigFileName(_ name: String) -> Bool {
        name == preferredConfigFileName
    }

    static func configFileURL(in directory: URL) -> URL? {
        let preferredURL = directory.appendingPathComponent(preferredConfigFileName)
        if FileManager.default.fileExists(atPath: preferredURL.path) {
            return preferredURL
        }

        return nil
    }
}

private struct PipelineRun: Sendable {
    let pipeline: Pipeline
    let session: DebugSession
    let succeeded: Bool
    let outputRoot: String
}

private struct GenerationTargets: Sendable {
    let outputItemType: OutputArtifactType
    let containers: [String]
    let systems: [String]

    static let allContainers = GenerationTargets(
        outputItemType: .container,
        containers: [],
        systems: []
    )
}

private enum EngineError: LocalizedError {
    case inputNotFound(String)
    case noModelFiles(String)
    case pipelineFailed
    case blueprintOverrideRequiresTarget
    case conflictingGenerationTargetKinds
    case unsupportedGenerationTargetKind(String)
    case inlineBlueprintMissingMainScript

    var errorDescription: String? {
        switch self {
        case .inputNotFound(let path):
            return "Input path was not found: \(path)"
        case .noModelFiles(let path):
            return "No .modelhike model files were found in \(path)"
        case .pipelineFailed:
            return "The modelhike pipeline failed without returning structured diagnostics."
        case .blueprintOverrideRequiresTarget:
            return "When a blueprint override is provided, also pass at least one target selector: --container or --system-view."
        case .conflictingGenerationTargetKinds:
            return "Specify only one target kind per invocation: --container or --system-view."
        case .unsupportedGenerationTargetKind(let kind):
            return "Generation targeting for \(kind) is not yet supported in modelhike-smart-cli."
        case .inlineBlueprintMissingMainScript:
            return "Inline blueprint is missing required main.ss entry point script."
        }
    }
}

private enum OutputTreeBuilder {
    private final class Node {
        var children: [String: Node] = [:]
    }

    static func renderTree(for paths: [String]) -> String {
        guard !paths.isEmpty else { return "" }

        let root = Node()
        for path in paths {
            let parts = path.split(separator: "/").map(String.init)
            insert(parts, into: root)
        }

        var lines: [String] = []
        render(node: root, prefix: "", into: &lines)
        return lines.joined(separator: "\n")
    }

    private static func insert(_ parts: [String], into node: Node) {
        guard let head = parts.first else { return }
        let child = node.children[head] ?? Node()
        node.children[head] = child
        insert(Array(parts.dropFirst()), into: child)
    }

    private static func render(node: Node, prefix: String, into lines: inout [String]) {
        let entries = node.children.keys.sorted()
        for (index, key) in entries.enumerated() {
            let isLast = index == entries.count - 1
            let branch = isLast ? "└── " : "├── "
            lines.append(prefix + branch + key)
            if let child = node.children[key] {
                render(node: child, prefix: prefix + (isLast ? "    " : "│   "), into: &lines)
            }
        }
    }
}

