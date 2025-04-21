//
//  PipelinePhase.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct DiscoverPhase: PipelinePhase {
    public let name: String = "Discover"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [DiscoveringPass] = []

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) {pass, phase in

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(pipeline.ws, phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: DiscoverPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) { self.context = context }
}

public struct LoadPhase: PipelinePhase {
    public let name: String = "Load"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [LoadingPass] = []
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(pipeline.ws, phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: LoadPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) { self.context = context }
}

public struct HydratePhase: PipelinePhase {
    public let name: String = "Hydrate"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [HydrationPass] = []

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: HydratePhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) { self.context = context }
}

public struct TransformPhase: PipelinePhase {
    public let name: String = "Transform"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [TransformationPass] = []

    let pluginsPass = PluginsPass()

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: TransformPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) {
        self.context = context
        passes.append(pluginsPass)
    }
}

public struct RenderPhase: PipelinePhase {
    public let name: String = "Render"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [RenderingPass] = []

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        let sandbox = await pipeline.ws.newGenerationSandbox()
        await pipeline.append(sandbox: sandbox)

        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in

            if try await pass.canRunIn(phase: phase) {
                return try await pass.runIn(sandbox, phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: RenderPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) { self.context = context }
}

public struct PersistPhase: PipelinePhase {
    public let name: String = "Persist"
    public let context: LoadContext
    public var config: OutputConfig { get async { await context.config }}

    public var passes: [PersistancePass] = []

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in

            if try await pass.canRunIn(phase: phase, pipeline: pipeline) {
                return try await pass.runIn(phase: phase, pipeline: pipeline)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    public mutating func append(passes phase: PersistPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init(context: LoadContext) { self.context = context }
}

public protocol PipelinePhase: Sendable {
    associatedtype Pass: Sendable
    
    var name: String { get }
    var context: LoadContext { get }
    var config: OutputConfig { get async }

    var passes: [Pass] { get set }
    var hasPasses: Bool { get }

    mutating func append(pass: Pass)
    mutating func append(passes phase: Self)

    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
    
    func canRunIn(pipeline: Pipeline) -> Bool
}

extension PipelinePhase {
    public func canRunIn(pipeline: Pipeline) -> Bool {
        if !hasPasses {
            pipeline.ws.context.debugLog.pipelinePhaseCannotRun(self, msg: "No passes to run")
            return false
        } else {
            return true
        }
    }

    public mutating func append(pass: Pass) {
        passes.append(pass)
    }

    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(
        pipeline: Pipeline, passes: [Pass], runPass: @escaping (Pass, Self) async throws -> Bool
    ) async throws -> Bool {
        var lastRunResult = true

        for pass in passes {
            let success = try await runPass(pass, self)
            if !success {
                lastRunResult = false
                break
            }
        }

        return lastRunResult
    }
}
