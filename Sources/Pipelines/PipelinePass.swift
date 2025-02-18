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
}

public protocol LoadingPass : PipelinePass {
    func runIn(_ workspace: Workspace, phase: LoadPhase) async throws -> Bool
}

public protocol HydrationPass : PipelinePass {
    func runIn(phase: HydratePhase) async throws -> Bool
}

public protocol TransformationPass : PipelinePass {
    func runIn(phase: TransformPhase) async throws -> Bool
}

public protocol RenderingPass : PipelinePass {
    func runIn(_ sandbox: Sandbox, phase: RenderPhase) async throws -> Bool
}

public protocol PersistancePass : PipelinePass {
    func runIn(phase: PersistPhase) async throws -> Bool
}


