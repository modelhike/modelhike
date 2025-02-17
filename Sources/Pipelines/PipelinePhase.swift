//
// PipelinePhase.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class DiscoverPhase : PipelinePhase {
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

public class LoadPhase : PipelinePhase {
    public var passes: [LoadingPass] = []
    public var lastRunResult: Bool = true
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(pipeline.ws, phase: phase)
        }
    }
    
    public init () { }
    
    public func setupDefaultPasses() {
//        append(pass: Load.contentsFrom(folder: "contents"))
//        append(pass: LoadPagesPass(folderName: "localFolder"))
//        append(pass: LoadTemplatesPass(folderName: "localFolder"))
        append(pass: LoadModelsPass())
    }
}

public class HydratePhase : PipelinePhase {
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

public class TransformPhase : PipelinePhase {
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
    
    public func setupDefaultPasses() {
        append(pass: pluginsPass)
    }
}

public class RenderPhase : PipelinePhase {
    public var passes: [RenderingPass] = []
    public var lastRunResult: Bool = true
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(pipeline.ws, phase: phase)
        }
    }
    
    public func setupDefaultPasses() {
        append(pass: GenerateCodePass())
    }
    public init () { }
}

public class PersistPhase : PipelinePhase {
    public var passes: [PersistancePass] = []
    public var lastRunResult: Bool = true

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        return try await runIn(pipeline: pipeline, passes: passes) { pass, phase in
            try await pass.runIn(phase: phase)
        }
    }
    
    public init () { }
    
    public func setupDefaultPasses() {
        append(pass: GenerateFoldersPass())
        append(pass: GenerateFiles())
    }
}

public protocol PipelinePhase : AnyObject {
    associatedtype Pass
    var passes: [Pass] {get set}
    
    var lastRunResult: Bool {get set}
    var hasPasses: Bool {get}
    
    func append(pass: Pass)
    
    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
    
    func setupDefaultPasses()
}

public extension PipelinePhase {
    func append(pass: Pass) {
        passes.append(pass)
    }
    
    var hasPasses: Bool { passes.count > 0 }
    
    func setupDefaultPasses() {
    }
    
    @discardableResult
    func runIn(pipeline: Pipeline, passes: [Pass], runPass: @escaping (Pass, Self) async throws -> Bool) async throws -> Bool {
        self.lastRunResult = true

        for pass in passes {
            let success = try await runPass(pass, self)
            if !success {
                self.lastRunResult = false
                break
            }
        }

        return self.lastRunResult
    }
}
