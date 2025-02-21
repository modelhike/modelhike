//
// PipelinePass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol PipelinePass {
}

public protocol DiscoveringPass : PipelinePass {
    func runIn(phase: DiscoverPhase) async throws -> Bool
    func canRunIn(phase: DiscoverPhase) throws -> Bool
}

public protocol LoadingPass : PipelinePass {
    func runIn(_ workspace: Workspace, phase: LoadPhase) async throws -> Bool
    func canRunIn(phase: LoadPhase) throws -> Bool
}

public protocol HydrationPass : PipelinePass {
    func runIn(phase: HydratePhase) async throws -> Bool
    func canRunIn(phase: HydratePhase) throws -> Bool
}

public protocol TransformationPass : PipelinePass {
    func runIn(phase: TransformPhase) async throws -> Bool
    func canRunIn(phase: TransformPhase) throws -> Bool
}

public protocol RenderingPass : PipelinePass {
    func runIn(_ sandbox: Sandbox, phase: RenderPhase) async throws -> Bool
    func canRunIn(phase: RenderPhase) throws -> Bool
}

public protocol PersistancePass : PipelinePass {
    func runIn(phase: PersistPhase) async throws -> Bool
    func canRunIn(phase: PersistPhase) throws -> Bool
}

public extension DiscoveringPass {
    func canRunIn(phase: DiscoverPhase) -> Bool {
        return true
    }
}

public extension LoadingPass {
    func canRunIn(phase: LoadPhase) -> Bool {
        return true
    }
}

public extension HydrationPass {
    func canRunIn(phase: HydratePhase) -> Bool {
        return true
    }
}

public extension TransformationPass {
    func canRunIn(phase: TransformPhase) -> Bool {
        return true
    }
}

public extension RenderingPass {
    func canRunIn(phase: RenderPhase) -> Bool {
        return true
    }
}

public extension PersistancePass {
    func canRunIn(phase: PersistPhase) -> Bool {
        return true
    }
}

