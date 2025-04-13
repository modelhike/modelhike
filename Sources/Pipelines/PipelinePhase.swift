//
//  PipelinePhase.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor DiscoverPhase: PipelinePhase {
    public let name: String = "Discover"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [DiscoveringPass] = []
    public private(set) var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(pipeline.ws, phase: phase)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: DiscoverPhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) { self.context = context }
}

public actor LoadPhase: PipelinePhase {
    public let name: String = "Load"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [LoadingPass] = []
    public private(set) var lastRunResult: Bool = true
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(pipeline.ws, phase: phase)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: LoadPhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) { self.context = context }
}

public actor HydratePhase: PipelinePhase {
    public let name: String = "Hydrate"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [HydrationPass] = []
    public private(set) var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: HydratePhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) { self.context = context }
}

public actor TransformPhase: PipelinePhase {
    public let name: String = "Transform"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [TransformationPass] = []
    public private(set) var lastRunResult: Bool = true

    let pluginsPass = PluginsPass()

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: TransformPhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) {
        self.context = context
        passes.append(pluginsPass)
    }
}

public actor RenderPhase: PipelinePhase {
    public let name: String = "Render"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [RenderingPass] = []
    public private(set) var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        let sandbox = await pipeline.ws.newGenerationSandbox()
        await pipeline.append(sandbox: sandbox)

        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(sandbox, phase: phase)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: RenderPhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) { self.context = context }
}

public actor PersistPhase: PipelinePhase {
    public let name: String = "Persist"
    public private(set) var context: LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [PersistancePass] = []
    public private(set) var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {[weak self] pass, phase in
            guard let self = self else { return false }

            if try await pass.canRunIn(phase: phase, pipeline: pipeline) {
                return try await pass.runIn(phase: phase, pipeline: pipeline)
            } else {
                await context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public func append(passes phase: PersistPhase) async {
        passes.append(contentsOf: await phase.passes)
    }

    public func lastRunResult(_ value: Bool) {
        self.lastRunResult = value
    }
    
    public init(context: LoadContext) { self.context = context }
}

public protocol PipelinePhase: Actor {
    associatedtype Pass
    
    var name: String { get }
    var context: LoadContext { get }
    var config: OutputConfig { get }

    var passes: [Pass] { get set }

    var lastRunResult: Bool { get }
    func lastRunResult(_ value: Bool)
    var hasPasses: Bool { get }

    func append(pass: Pass) async
    func append(passes phase: Self) async

    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
}

extension PipelinePhase {
    public func canRunIn(pipeline: Pipeline) async -> Bool {
        if !hasPasses {
            await pipeline.ws.context.debugLog.pipelinePhaseCannotRun(self, msg: "No passes to run")
            return false
        } else {
            return true
        }
    }

    public func append(pass: Pass) async {
        passes.append(pass)
    }

    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(
        pipeline: Pipeline, passes: [Pass], runPass: @escaping (Pass, Self) async throws -> Bool
    ) async throws -> Bool {
        self.lastRunResult(true)

        for pass in passes {
            let success = try await runPass(pass, self)
            if !success {
                self.lastRunResult(false)
                break
            }
        }

        return self.lastRunResult
    }
}
