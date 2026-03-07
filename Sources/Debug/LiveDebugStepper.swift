//
//  LiveDebugStepper.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Breakpoint location by file and line.
public struct BreakpointLocation: Hashable, Codable, Sendable {
    public let fileIdentifier: String
    public let lineNo: Int

    public init(fileIdentifier: String, lineNo: Int) {
        self.fileIdentifier = fileIdentifier
        self.lineNo = lineNo
    }
}

/// Step mode when resuming from a breakpoint.
public enum StepMode: String, Codable, Sendable {
    case run
    case stepOver
    case stepInto
    case stepOut
}

/// Callback when the stepper pauses at a breakpoint. Called before suspending.
public typealias StepperPauseCallback = @Sendable (SourceLocation, [String: String]) async -> Void

/// Live stepping implementation. Suspends at breakpoints using CheckedContinuation.
/// Requires the pipeline to run while the debug server is already listening (--debug-stepping mode).
public actor LiveDebugStepper: DebugStepper {
    private var breakpoints: Set<BreakpointLocation> = []
    private var continuation: CheckedContinuation<Void, Never>?
    private var mode: StepMode = .run
    private var onPause: StepperPauseCallback?

    public init() {}

    public func setOnPause(_ callback: StepperPauseCallback?) {
        onPause = callback
    }

    public func addBreakpoint(_ bp: BreakpointLocation) {
        breakpoints.insert(bp)
    }

    public func removeBreakpoint(_ bp: BreakpointLocation) {
        breakpoints.remove(bp)
    }

    public func resume(mode: StepMode = .run) {
        self.mode = mode
        continuation?.resume()
        continuation = nil
    }

    public func willExecute(item: TemplateItem, ctx: Context) async {
        guard let itemWithInfo = item as? TemplateItemWithParsedInfo else { return }
        let pInfo = itemWithInfo.pInfo
        let loc = BreakpointLocation(fileIdentifier: pInfo.identifier, lineNo: pInfo.lineNo)
        guard breakpoints.contains(loc) else { return }

        let sourceLoc = SourceLocation(
            fileIdentifier: pInfo.identifier,
            lineNo: pInfo.lineNo,
            lineContent: pInfo.line,
            level: pInfo.level
        )
        if let cb = onPause {
            let vars = await ctx.variablesForDebug()
            await cb(sourceLoc, vars)
        }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
        }
    }
}
