//
//  DebugRecorder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol DebugRecorder: Actor, Sendable {
    func record(_ envelope: DebugEventEnvelope) async
    /// Record a single event (convenience; builds envelope with sequenceNo, timestamp, containerName).
    func recordEvent(_ event: DebugEvent) async
    func recordGeneratedFile(outputPath: String, templateName: String?, objectName: String?, workingDir: String, source: SourceLocation) async
    func registerSourceFile(_ file: SourceFile) async
    func setContainerName(_ name: String?) async
    func captureModel(_ model: AppModel) async
    func captureBaseSnapshot(label: String, variables: [String: String]) async
    func captureDelta(eventIndex: Int, variable: String, oldValue: String?, newValue: String) async
    func captureError(category: String, message: String, source: SourceLocation, callStack: [SourceLocation], memoryDump: [String: String]?) async
    func addGeneratedFile(outputPath: String, templateName: String?, objectName: String?, workingDir: String) async
    func recordPhaseStarted(name: String) async
    func recordPhaseCompleted(name: String, success: Bool, errorMessage: String?) async
    func session(config: OutputConfig) async -> DebugSession
}

public actor DefaultDebugRecorder: DebugRecorder {
    private var events: [DebugEventEnvelope] = []
    private var sourceFileMap = SourceFileMap()
    private var containerName: String?
    private var modelSnapshot: ModelSnapshot?
    private var baseSnapshots: [MemorySnapshot] = []
    private var deltaSnapshots: [DeltaSnapshot] = []
    private var errors: [ErrorRecord] = []
    private var generatedFiles: [GeneratedFileRecord] = []
    private var phaseRecords: [PhaseRecord] = []
    private var currentPhaseStart: Date?
    private var sequenceNo = 0

    public init() {}

    public func record(_ envelope: DebugEventEnvelope) async {
        events.append(envelope)
    }

    public func recordEvent(_ event: DebugEvent) async {
        sequenceNo += 1
        let envelope = DebugEventEnvelope(sequenceNo: sequenceNo, timestamp: Date(), containerName: containerName, event: event)
        await record(envelope)
    }

    public func recordGeneratedFile(outputPath: String, templateName: String?, objectName: String?, workingDir: String, source: SourceLocation) async {
        await recordEvent(.fileGenerated(outputPath: outputPath, templateName: templateName, objectName: objectName, source: source))
        let record = GeneratedFileRecord(
            outputPath: outputPath,
            templateName: templateName,
            objectName: objectName,
            workingDir: workingDir,
            eventIndex: max(0, events.count - 1)
        )
        generatedFiles.append(record)
    }

    public func registerSourceFile(_ file: SourceFile) async {
        await sourceFileMap.register(identifier: file.identifier, content: file.content, fullPath: file.fullPath, fileType: file.fileType)
    }

    public func setContainerName(_ name: String?) async {
        containerName = name
    }

    public func captureModel(_ model: AppModel) async {
        let containers = await buildContainerSnapshots(from: model)
        modelSnapshot = ModelSnapshot(containers: containers)
    }

    public func captureBaseSnapshot(label: String, variables: [String: String]) async {
        let snapshot = MemorySnapshot(label: label, timestamp: Date(), eventIndex: events.count, variables: variables)
        baseSnapshots.append(snapshot)
    }

    public func captureDelta(eventIndex: Int, variable: String, oldValue: String?, newValue: String) async {
        let delta = DeltaSnapshot(eventIndex: eventIndex, variable: variable, oldValue: oldValue, newValue: newValue)
        deltaSnapshots.append(delta)
    }

    public func captureError(category: String, message: String, source: SourceLocation, callStack: [SourceLocation], memoryDump: [String: String]?) async {
        let record = ErrorRecord(category: category, message: message, source: source, callStack: callStack, memoryDump: memoryDump)
        errors.append(record)
    }

    public func addGeneratedFile(outputPath: String, templateName: String?, objectName: String?, workingDir: String) async {
        let record = GeneratedFileRecord(outputPath: outputPath, templateName: templateName, objectName: objectName, workingDir: workingDir, eventIndex: events.count)
        generatedFiles.append(record)
    }

    /// Reconstruct variable state at a given event index.
    public func reconstructState(atEventIndex eventIndex: Int) async -> [String: String] {
        var vars: [String: String] = [:]
        var bestBase: MemorySnapshot?
        for base in baseSnapshots where base.eventIndex <= eventIndex {
            if bestBase == nil || base.eventIndex > (bestBase?.eventIndex ?? -1) {
                bestBase = base
            }
        }
        if let base = bestBase {
            vars = base.variables
        }
        for delta in deltaSnapshots where delta.eventIndex <= eventIndex {
            vars[delta.variable] = delta.newValue
        }
        return vars
    }

    public func recordPhaseStarted(name: String) async {
        currentPhaseStart = Date()
        phaseRecords.append(PhaseRecord(name: name, startedAt: Date(), completedAt: nil, duration: nil, success: false, errorMessage: nil))
    }

    public func recordPhaseCompleted(name: String, success: Bool, errorMessage: String?) async {
        let now = Date()
        let duration = currentPhaseStart.map { now.timeIntervalSince($0) }
        if let lastIndex = phaseRecords.indices.last {
            phaseRecords[lastIndex] = PhaseRecord(name: name, startedAt: phaseRecords[lastIndex].startedAt, completedAt: now, duration: duration, success: success, errorMessage: errorMessage)
        }
        currentPhaseStart = nil
    }

    public func session(config: OutputConfig) async -> DebugSession {
        let configSnapshot = ConfigSnapshot(
            basePath: await config.basePath.string,
            outputPath: await config.output.path.string,
            containersToOutput: await config.containersToOutput
        )
        return DebugSession(
            timestamp: Date(),
            config: configSnapshot,
            phases: phaseRecords,
            model: modelSnapshot ?? ModelSnapshot(containers: []),
            events: events,
            sourceFiles: await sourceFileMap.allFiles(),
            files: generatedFiles,
            errors: errors,
            baseSnapshots: baseSnapshots,
            deltaSnapshots: deltaSnapshots
        )
    }

    func sourceLocation(from pInfo: ParsedInfo) -> SourceLocation {
        SourceLocation(fileIdentifier: pInfo.identifier, lineNo: pInfo.lineNo, lineContent: pInfo.line, level: pInfo.level)
    }

    private func buildContainerSnapshots(from model: AppModel) async -> [ContainerSnapshot] {
        var result: [ContainerSnapshot] = []
        let containers = await model.containers.snapshot()
        for container in containers {
            let name = await container.name
            let givenname = await container.givenname
            let containerType = String(describing: await container.containerType)
            let components = await container.components.snapshot()
            var modules: [ModuleSnapshot] = []
            for comp in components {
                modules.append(await buildModuleSnapshot(from: comp))
            }
            result.append(ContainerSnapshot(name: name, givenname: givenname, containerType: containerType, modules: modules))
        }
        return result
    }

    private func buildModuleSnapshot(from component: C4Component) async -> ModuleSnapshot {
        let name = await component.name
        let givenname = await component.givenname
        var objects: [ObjectSnapshot] = []
        var submodules: [ModuleSnapshot] = []
        for item in await component.items {
            if let submodule = item as? C4Component {
                submodules.append(await buildModuleSnapshot(from: submodule))
            } else if let codeObj = item as? CodeObject {
                objects.append(await buildObjectSnapshot(from: codeObj))
            }
        }
        return ModuleSnapshot(name: name, givenname: givenname, objects: objects, submodules: submodules)
    }

    private func buildObjectSnapshot(from obj: CodeObject) async -> ObjectSnapshot {
        let name = await obj.name
        let givenname = await obj.givenname
        let kind = String(describing: await obj.dataType)
        var properties: [PropertySnapshot] = []
        for prop in await obj.properties {
            properties.append(PropertySnapshot(
                name: await prop.name,
                givenname: await prop.givenname,
                typeName: await prop.type.objectString(),
                required: String(describing: await prop.required)
            ))
        }
        var methods: [MethodSnapshot] = []
        for method in await obj.methods {
            let params = await method.parameters.map { $0.name }
            methods.append(MethodSnapshot(
                name: await method.name,
                givenname: await method.givenname,
                parameters: params,
                returnType: await method.returnType.objectString()
            ))
        }
        var annotations: [String] = []
        if let hasAnnotations = obj as? any HasAnnotations_Actor {
            let anns = await hasAnnotations.annotations.annotationsList
            annotations = anns.map { $0.name }
        }
        var tags: [String] = []
        if let hasTags = obj as? any HasTags_Actor {
            var tagNames: [String] = []
            try? await hasTags.tags.processEach { tag in
                tagNames.append(tag.name)
                return tag
            }
            tags = tagNames
        }
        var apis: [APISnapshot] = []
        for artifact in await obj.attached {
            if let api = artifact as? GenericAPI {
                let state = await api.state
                let typeStr = String(describing: await state.type)
                apis.append(APISnapshot(name: await api.name, type: typeStr))
            }
        }
        return ObjectSnapshot(name: name, givenname: givenname, kind: kind, properties: properties, methods: methods, annotations: annotations, tags: tags, apis: apis)
    }
}
