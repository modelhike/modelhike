//
// PipelinePhase.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct DiscoverPhase : PipelinePhase {
    public var passes: [DiscoveringPass] = []
    public var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    mutating public func append(passes phase: DiscoverPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () { }
}

public struct LoadPhase : PipelinePhase {
    public var passes: [LoadingPass] = []
    public var lastRunResult: Bool = true
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(pipeline.ws, phase: phase)
        }
    }
    
    mutating public func append(passes phase: LoadPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () { }
}

public struct HydratePhase : PipelinePhase {
    public var passes: [HydrationPass] = []
    public var lastRunResult: Bool = true
        
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    mutating public func append(passes phase: HydratePhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () { }
}

public struct TransformPhase : PipelinePhase {
    public var passes: [TransformationPass] = []
    public var lastRunResult: Bool = true
    
    let pluginsPass = PluginsPass()

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    mutating public func append(passes phase: TransformPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () {
        append(pass: pluginsPass)
    }
}

public struct RenderPhase : PipelinePhase {
    public var passes: [RenderingPass] = []
    public var lastRunResult: Bool = true
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(pipeline.ws, phase: phase)
        }
    }

    mutating public func append(passes phase: RenderPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () { }
}

public struct PersistPhase : PipelinePhase {
    public var passes: [PersistancePass] = []
    public var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    mutating public func append(passes phase: PersistPhase) {
        passes.append(contentsOf: phase.passes)
    }
    
    public init () { }
}

public protocol PipelinePhase {
    associatedtype Pass
    var passes: [Pass] {get set}
    
    var lastRunResult: Bool {get set}
    var hasPasses: Bool {get}
    
    mutating func append(pass: Pass)
    mutating func append(passes phase: Self)
    
    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
}

public extension PipelinePhase {
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
