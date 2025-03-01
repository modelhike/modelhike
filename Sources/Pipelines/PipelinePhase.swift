//
// PipelinePhase.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct DiscoverPhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [DiscoveringPass] = []
    public var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }
    
    mutating public func append(passes phase: DiscoverPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) { self.context = context }
}

public struct LoadPhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [LoadingPass] = []
    public var lastRunResult: Bool = true
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase) {
                return try await pass.runIn(pipeline.ws, phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }
    
    mutating public func append(passes phase: LoadPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) { self.context = context }
}

public struct HydratePhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [HydrationPass] = []
    public var lastRunResult: Bool = true
        
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }
    
    mutating public func append(passes phase: HydratePhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) { self.context = context }
}

public struct TransformPhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }

    public var passes: [TransformationPass] = []
    public var lastRunResult: Bool = true
    
    let pluginsPass = PluginsPass()

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase) {
                return try await pass.runIn(phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }
    
    mutating public func append(passes phase: TransformPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) {
        self.context = context
        append(pass: pluginsPass)
    }
}

public struct RenderPhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }
    
    public var passes: [RenderingPass] = []
    public var lastRunResult: Bool = true
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        let sandbox = pipeline.ws.newGenerationSandbox()
        pipeline.generationSandboxes.append(sandbox)
        
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase) {
                return try await pass.runIn(sandbox, phase: phase)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }

    mutating public func append(passes phase: RenderPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) { self.context = context }
}

public struct PersistPhase : PipelinePhase {
    public private(set) var context : LoadContext
    public var config: OutputConfig { context.config }
    
    public var passes: [PersistancePass] = []
    public var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            if try pass.canRunIn(phase: phase, pipeline: pipeline) {
                return try await pass.runIn(phase: phase, pipeline: pipeline)
            } else {
                context.debugLog.pipelinePassCannotRun(pass)
                return false
            }
        }
    }
    
    mutating public func append(passes phase: PersistPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init (context: LoadContext) { self.context = context }
}

public protocol PipelinePhase {
    associatedtype Pass
    var context : LoadContext {get}
    var config: OutputConfig {get}

    var passes: [Pass] {get set}
    
    var lastRunResult: Bool {get set}
    var hasPasses: Bool {get}
    
    mutating func append(pass: Pass)
    mutating func append(passes phase: Self)
    
    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
}

public extension PipelinePhase {
    func canRunIn(pipeline: Pipeline) -> Bool {
        if !hasPasses {
            pipeline.ws.context.debugLog.pipelinePhaseCannotRun(self, msg: "No passes to run")
            return false
        } else {
            return true
        }
    }
    
    mutating func append(pass: Pass) {
        passes.append(pass)
    }
    
    var hasPasses: Bool { passes.count > 0 }
    
    @discardableResult
    func runIn(pipeline: Pipeline, passes: [Pass], runPass: @escaping (Pass, Self) async throws -> Bool) async throws -> Bool {
        var mutableSelf = self
        mutableSelf.lastRunResult = true

        for pass in passes {
            let success = try await runPass(pass, mutableSelf)
            if !success {
                mutableSelf.lastRunResult = false
                break
            }
        }

        return mutableSelf.lastRunResult
    }
}
