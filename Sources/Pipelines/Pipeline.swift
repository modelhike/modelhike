//
//  Pipeline.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor Pipeline {
    var ws = Workspace()
            
    let discover: DiscoverPhase
    let load: LoadPhase
    let hydrate: HydratePhase
    let transform: TransformPhase
    let render: RenderPhase
    let persist: PersistPhase
    
    var phases: [any PipelinePhase] = []
    
    public internal(set) var generationSandboxes: [GenerationSandbox] = []
    
    public var config: OutputConfig { ws.config }
        
    @discardableResult
    public func run(using config: OutputConfig) async throws -> Bool {
        do {
            ws.config = config
            
            return try await runPhases()
        } catch let err {
            printError(err)
            print("❌❌❌ TERMINATED DUE TO ERROR ❌❌❌")
            return false
        }
    }
    
    public func render(string input: String, data: [String : Any]) throws -> String? {
        do {
            ws.config = PipelineConfig()
            
            return try ws.render(string: input, data: data)
            
        } catch let err {
            printError(err)
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
                print("❌❌ ERROR OCCURRED IN \(await phase.name) Phase ❌❌")
                throw err
            }
        }
        
        return lastRunResult

    }
    
    public func append(sandbox: GenerationSandbox) {
        generationSandboxes.append(sandbox)
    }
    
    public init(@PipelineBuilder _ builder: () -> [PipelinePass]) async {
        let context = await ws.context
        discover = DiscoverPhase(context: context)
        load = LoadPhase(context: context)
        hydrate = HydratePhase(context: context)
        transform = TransformPhase(context: context)
        render = RenderPhase(context: context)
        persist = PersistPhase(context: context)
        
        let providedPasses = builder()
        
        for pass in providedPasses {
            if let dp = pass as? DiscoveringPass {
                await discover.append(pass: dp)
            } else if let lp = pass as? LoadingPass {
                await load.append(pass: lp)
            } else if let hp = pass as? HydrationPass {
                await hydrate.append(pass: hp)
            } else if let tp = pass as? TransformationPass {
                await transform.append(pass: tp)
            } else if let rp = pass as? RenderingPass {
                await render.append(pass: rp)
            } else if let pp = pass as? PersistancePass {
                await persist.append(pass: pp)
            }
        }
        
        phases = [discover, load, hydrate, transform, render, persist]
    }
    
    public init(from pipe: Pipeline, @PipelineBuilder _ builder: () -> [PipelinePass]) async {
        let context = await ws.context
        discover = DiscoverPhase(context: context)
        load = LoadPhase(context: context)
        hydrate = HydratePhase(context: context)
        transform = TransformPhase(context: context)
        render = RenderPhase(context: context)
        persist = PersistPhase(context: context)
        
        let providedPasses = builder()
        
        await discover.append(passes: pipe.discover)
        await load.append(passes: pipe.load)
        await hydrate.append(passes: pipe.hydrate)
        await transform.append(passes: pipe.transform)
        await render.append(passes: pipe.render)
        await persist.append(passes: pipe.persist)

        
        for pass in providedPasses {
            if let dp = pass as? DiscoveringPass {
                await discover.append(pass: dp)
            } else if let lp = pass as? LoadingPass {
                await load.append(pass: lp)
            } else if let hp = pass as? HydrationPass {
                await hydrate.append(pass: hp)
            } else if let tp = pass as? TransformationPass {
                await transform.append(pass: tp)
            } else if let rp = pass as? RenderingPass {
                await render.append(pass: rp)
            } else if let pp = pass as? PersistancePass {
                await persist.append(pass: pp)
            }
        }
        
        phases = [discover, load, hydrate, transform, render, persist]
    }
    
    fileprivate func printError(_ err: Error) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: ws)
    }
}

typealias PipelineBuilder = ResultBuilder<PipelinePass>

