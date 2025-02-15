//
// PipelinePhase.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class DiscoverPhase : PipelinePhase {
    var passes: [DiscoveringPass] = []
    public var lastRunResult: Bool = true
    
    public func append(pass: DiscoveringPass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
}

public class LoadPhase : PipelinePhase {
    var passes: [LoadingPass] = []
    public var lastRunResult: Bool = true
    
    public func append(pass: LoadingPass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
    
    public func setupDefaultPasses() {
        passes.append(Load.contentsFrom(folder: "contents"))
        passes.append(LoadPagesPass(folderName: "localFolder"))
        passes.append(LoadTemplatesPass(folderName: "localFolder"))
    }
}

public class HydratePhase : PipelinePhase {
    var passes: [HydrationPass] = []
    public var lastRunResult: Bool = true
    
    public func append(pass: HydrationPass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
}

public class TransformPhase : PipelinePhase {
    var passes: [TransformationPass] = []
    public var lastRunResult: Bool = true
    
    let pluginsPass = PluginsPass()

    public func append(pass: TransformationPass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
    
    public func setupDefaultPasses() {
        passes.append(pluginsPass)
    }
}

public class RenderPhase : PipelinePhase {
    var passes: [RenderingPass] = []
    public var lastRunResult: Bool = true
    
    public func append(pass: RenderingPass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }
    
    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
}

public class PersistPhase : PipelinePhase {
    var passes: [PersistancePass] = []
    public var lastRunResult: Bool = true
    
    public func append(pass: PersistancePass) {
        passes.append(pass)
    }
    
    public var hasPasses: Bool { passes.count > 0 }

    @discardableResult
    public func runIn(pipeline: Pipeline) async throws -> Bool {
        lastRunResult = true

        do {
            for pass in passes {
                let success = try await pass.runIn(phase: self)
                if !success { lastRunResult = false; break }
            }
        } catch {
            print("Error: \(error)")
        }
        
        return lastRunResult
    }
    
    public init () { }
    
    public func setupDefaultPasses() {
        passes.append(GenerateFoldersPass())
        passes.append(GenerateFiles())
    }
}

public protocol PipelinePhase {
    var lastRunResult: Bool {get}
    var hasPasses: Bool {get}
    
    @discardableResult
    func runIn(pipeline: Pipeline) async throws -> Bool
    
    func setupDefaultPasses()
}

public extension PipelinePhase {
    func setupDefaultPasses() {
    }
}
