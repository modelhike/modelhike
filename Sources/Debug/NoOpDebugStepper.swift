//
//  NoOpDebugStepper.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

/// No-op implementation of DebugStepper. Used when --debug is active but live stepping is not yet implemented.
public actor NoOpDebugStepper: DebugStepper {
    public init() {}
    public func willExecute(item: TemplateItem, ctx: Context) async {}
}
