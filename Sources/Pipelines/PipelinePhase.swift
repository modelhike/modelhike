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
    
    public init () { }
}

public struct LoadPhase : PipelinePhase {
    public var passes: [LoadingPass] = []
    public var lastRunResult: Bool = true
    
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    public init () { }
    
    public mutating func setupDefaultPasses() {
        append(pass: Load.contentsFrom(folder: "contents"))
        append(pass: LoadPagesPass(folderName: "localFolder"))
        append(pass: LoadTemplatesPass(folderName: "localFolder"))
    }
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
    
    public init () { }
    
    public mutating func setupDefaultPasses() {
        append(pass: pluginsPass)
    }
}

public struct RenderPhase : PipelinePhase {
    public var passes: [RenderingPass] = []
    public var lastRunResult: Bool = true
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
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
    
    public init () { }
    
    public mutating func setupDefaultPasses() {
        append(pass: GenerateFoldersPass())
        append(pass: GenerateFiles())
    }
}

public protocol PipelinePhase {
    associatedtype Pass
    var passes: [Pass] {get set}
    
    var lastRunResult: Bool {get set}
    var hasPasses: Bool {get}
    
    mutating func append(pass: Pass)
    
    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
    
    func setupDefaultPasses()
}

public extension PipelinePhase {
    mutating func append(pass: Pass) {
        passes.append(pass)
    }
    
    var hasPasses: Bool { passes.count > 0 }
    
    func setupDefaultPasses() {
    }
    
    @discardableResult
    func runIn(pipeline: Pipeline, passes: [Pass], runPass: @escaping (Pass, Self) async throws -> Bool) async throws -> Bool {
        var mutableSelf = self
        mutableSelf.lastRunResult = true

        do {
            for pass in passes {
                let success = try await runPass(pass, mutableSelf)
                if !success {
                    mutableSelf.lastRunResult = false
                    break
                }
            }
        } catch {
            print("Error: \(error)")
        }

        return mutableSelf.lastRunResult
    }
}
