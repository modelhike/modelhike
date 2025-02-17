//
// Pipeline.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct Pipeline {
    public var outputs = OutputFolder("output")

    var lastRunResult: Bool = true
    var discover = DiscoverPhase()
    var load = LoadPhase()
    var hydrate = HydratePhase()
    var transform = TransformPhase()
    var render = RenderPhase()
    var persist = PersistPhase()
    
    lazy var phases: [any PipelinePhase] = [discover, load, hydrate, transform, render, persist]

    @discardableResult
    public mutating func run() async -> Bool {
        lastRunResult = true

        do {
            for phase in phases {
                let success = try await phase.runIn(pipeline: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init(@PipelineBuilder _ builder: () -> [PipelinePass]) {
        
        let providedPasses = builder()
        
        for pass in providedPasses {
            if let dp = pass as? DiscoveringPass {
                discover.append(pass: dp)
            } else if let lp = pass as? LoadingPass {
                load.append(pass: lp)
            } else if let hp = pass as? HydrationPass {
                hydrate.append(pass: hp)
            } else if let tp = pass as? TransformationPass {
                transform.append(pass: tp)
            } else if let rp = pass as? RenderingPass {
                render.append(pass: rp)
            } else if let pp = pass as? PersistancePass {
                persist.append(pass: pp)
            }
        }
        
        for phase in phases {
            if !phase.hasPasses {
                phase.setupDefaultPasses()
            }
        }
    }
}

typealias PipelineBuilder = ResultBuilder<PipelinePass>

