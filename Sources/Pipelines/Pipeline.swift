//
// Pipeline.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class Pipeline {
    var ws = Workspace()
            
    var discover: DiscoverPhase
    var load: LoadPhase
    var hydrate: HydratePhase
    var transform: TransformPhase
    var render: RenderPhase
    var persist: PersistPhase
    
    var phases: [any PipelinePhase] = []
    
    public internal(set) var generationSandboxes: [GenerationSandbox] = []
    
    public var config: OutputConfig { ws.config }
        
    @discardableResult
    public func run(using config: OutputConfig) async throws -> Bool {
        do {
            ws.config = config
            
            //ws.debugLog.flags.fileGeneration = true
            
    //        ws.context.events.onBeforeRenderFile = { filename, context in
    //            if filename.lowercased() == "MonitoredLiveAirport".lowercased() {
    //                print("rendering \(filename)")
    //            }
    //
    //            return true
    //        }
            
    //        ws.context.events.onBeforeParseTemplate = { templatename, context in
    //            if templatename.lowercased() == "entity.validator.teso".lowercased() {
    //                print("rendering \(templatename)")
    //            }
    //        }
    //
    //        ws.context.events.onBeforeExecuteTemplate = { templatename, context in
    //            if templatename.lowercased() == "entity.validator.teso".lowercased() {
    //                print("rendering \(templatename)")
    //            }
    //        }
            
    //        ws.context.events.onStartParseObject = { objname, parser, context in
    //            print(objname)
    //            if objname.lowercased() == "airport".lowercased() {
    //                context.debugLog.flags.lineByLineParsing = true
    //            } else {
    //                context.debugLog.flags.lineByLineParsing = false
    //            }
    //        }
                        
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
            let success = try await phase.runIn(pipeline: self)
            if !success { lastRunResult = false; break }
        }
        
        return lastRunResult
    }
    
    public init(@PipelineBuilder _ builder: () -> [PipelinePass]) {
        discover = DiscoverPhase(context: ws.context)
        load = LoadPhase(context: ws.context)
        hydrate = HydratePhase(context: ws.context)
        transform = TransformPhase(context: ws.context)
        render = RenderPhase(context: ws.context)
        persist = PersistPhase(context: ws.context)
        
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
        
        phases = [discover, load, hydrate, transform, render, persist]
    }
    
    public init(from pipe: Pipeline, @PipelineBuilder _ builder: () -> [PipelinePass]) {
        discover = DiscoverPhase(context: ws.context)
        load = LoadPhase(context: ws.context)
        hydrate = HydratePhase(context: ws.context)
        transform = TransformPhase(context: ws.context)
        render = RenderPhase(context: ws.context)
        persist = PersistPhase(context: ws.context)
        
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
        
        phases = [discover, load, hydrate, transform, render, persist]
    }
    
    fileprivate func printError(_ err: Error) {
        let printer = PipelineErrorPrinter()
        printer.printError(err, workspace: ws)
    }
}

typealias PipelineBuilder = ResultBuilder<PipelinePass>

