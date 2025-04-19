//
//  LoadPagesPass.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor LoadPagesPass : LoadingPass {
    public let folderName: String
    public var markupDocs: [MarkupDocument] = []
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        return true
    }
    
    public func add(_ doc: MarkupDocument) {
        markupDocs.append(doc)
    }
    
    public init(folderName: String) {
        self.folderName = folderName
    }
}
