//
//  DebugStepper.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// Protocol for live stepping support. When set on context, the execution loop
/// calls `willExecute` before each template item. Used with `--debug` flag for
/// breakpoint-based debugging. Phase 1: no-op implementation.
public protocol DebugStepper: Actor, Sendable {
    func willExecute(item: TemplateItem, ctx: Context) async
}
