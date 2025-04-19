//
//  LoadContentFromFolder.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor LoadContentFromFolder : LoadingPass {
    public let folderName: String
    public let afterModifiedDate: Date?
    public var markupDocs: [MarkupDocument] = []
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        return true
    }
    
    public func add(_ doc: MarkupDocument) {
        markupDocs.append(doc)
    }
    
    public init(folderName: String, afterModifiedDate: Date? = nil) {
        self.folderName = folderName
        self.afterModifiedDate = afterModifiedDate
    }
}
