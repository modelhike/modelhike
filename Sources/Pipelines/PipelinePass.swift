//
//  PipelinePass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol PipelinePass: Sendable {
}

public protocol DiscoveringPass : PipelinePass {
    func runIn(_ workspace: Workspace, phase: DiscoverPhase) async throws -> Bool
    func canRunIn(phase: DiscoverPhase) async throws -> Bool
}

public protocol LoadingPass : PipelinePass {
    func runIn(_ workspace: Workspace, phase: LoadPhase) async throws -> Bool
    func canRunIn(phase: LoadPhase) async throws -> Bool
}

public protocol HydrationPass : PipelinePass {
    func runIn(phase: HydratePhase) async throws -> Bool
    func canRunIn(phase: HydratePhase) async throws -> Bool
}

public protocol TransformationPass : PipelinePass {
    func runIn(phase: TransformPhase) async throws -> Bool
    func canRunIn(phase: TransformPhase) async throws -> Bool
}

public protocol RenderingPass : PipelinePass {
    func runIn(_ sandbox: GenerationSandbox, phase: RenderPhase) async throws -> Bool
    func canRunIn(phase: RenderPhase) async throws -> Bool
}

public protocol PersistancePass : PipelinePass {
    func runIn(phase: PersistPhase, pipeline: Pipeline) async throws -> Bool
    func canRunIn(phase: PersistPhase, pipeline: Pipeline) async throws -> Bool
}

public extension DiscoveringPass {
    func canRunIn(phase: DiscoverPhase) async -> Bool {
        return true
    }
}

public extension LoadingPass {
    func canRunIn(phase: LoadPhase) async -> Bool {
        return true
    }
}

public extension HydrationPass {
    func canRunIn(phase: HydratePhase) async -> Bool {
        return true
    }
}

public extension TransformationPass {
    func canRunIn(phase: TransformPhase) async -> Bool {
        return true
    }
}

public extension RenderingPass {
    func canRunIn(phase: RenderPhase) async -> Bool {
        return true
    }
}

public extension PersistancePass {
    func canRunIn(phase: PersistPhase, pipeline: Pipeline) async -> Bool {
        return true
    }
}

