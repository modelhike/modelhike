//
//  Pipeline.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct Pipeline: Sendable {
    var ws: Workspace
            
    let discover: DiscoverPhase
    let load: LoadPhase
    let hydrate: HydratePhase
    let transform: TransformPhase
    let render: RenderPhase
    let persist: PersistPhase
    
    let phases: [any PipelinePhase]
    
    public let state = PipelineState()
    
    public var config: OutputConfig { get async { await ws.config }}
        
    @discardableResult
    public func run(using config: OutputConfig) async throws -> Bool {
        do {
            await ws.config(config)
            
            return try await runPhases()
        } catch let err {
            await printError(err)
            print("❌❌❌ TERMINATED DUE TO ERROR ❌❌❌")
            return false
        }
    }
    
    public func render(string input: String, data: [String : Sendable]) async throws -> String? {
        do {
            await ws.config(PipelineConfig())
            
            return try await ws.render(string: input, data: data)
            
        } catch let err {
            await printError(err)
            print("❌❌❌ TERMINATED DUE TO ERROR ❌❌❌")
            return nil
        }
    }
    
    fileprivate func runPhases() async throws -> Bool {
        var lastRunResult = true
        
        for phase in phases {
            do {
                let success = try await phase.runIn(pipeline: self)
                if !success { lastRunResult = false; break }
            } catch let err {
                print("❌❌ ERROR OCCURRED IN \(phase.name) Phase ❌❌")
                throw err
            }
        }
        
        return lastRunResult

    }
    
    public func append(sandbox: GenerationSandbox) async {
        await state.append(sandbox: sandbox)
    }
    
    public init(@PipelineBuilder _ builder: () -> [PipelinePass]) {
        ws = Workspace()
        
        let context = ws.context
        var discover = DiscoverPhase(context: context)
        var load = LoadPhase(context: context)
        var hydrate = HydratePhase(context: context)
        var transform = TransformPhase(context: context)
        var render = RenderPhase(context: context)
        var persist = PersistPhase(context: context)
        
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
        
        self.discover = discover
        self.load = load
        self.hydrate = hydrate
        self.transform = transform
        self.render = render
        self.persist = persist

        self.phases = [discover, load, hydrate, transform, render, persist]
    }
    
    public init(from pipe: Pipeline, @PipelineBuilder _ builder: () -> [PipelinePass]) async {
        ws = Workspace()
        
        let context = ws.context
        var discover = DiscoverPhase(context: context)
        var load = LoadPhase(context: context)
        var hydrate = HydratePhase(context: context)
        var transform = TransformPhase(context: context)
        var render = RenderPhase(context: context)
        var persist = PersistPhase(context: context)
        
        let providedPasses = builder()
        
        discover.append(passes: pipe.discover)
        load.append(passes: pipe.load)
        hydrate.append(passes: pipe.hydrate)
        transform.append(passes: pipe.transform)
        render.append(passes: pipe.render)
        persist.append(passes: pipe.persist)

        
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
        
        self.discover = discover
        self.load = load
        self.hydrate = hydrate
        self.transform = transform
        self.render = render
        self.persist = persist
        
        self.phases = [discover, load, hydrate, transform, render, persist]
    }
    
    fileprivate func printError(_ err: Error) async {
        let printer = PipelineErrorPrinter()
        await printer.printError(err, workspace: ws)
    }
}

typealias PipelineBuilder = ResultBuilder<PipelinePass>

public actor PipelineState {
    public internal(set) var generationSandboxes: [GenerationSandbox] = []
    
    public func append(sandbox: GenerationSandbox) {
        generationSandboxes.append(sandbox)
    }
    
    public init() {
    }
}
