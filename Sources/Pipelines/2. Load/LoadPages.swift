//
// LoadPagesPass.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct LoadPagesPass : LoadingPass {
    public let folderName: String
    public var markupDocs: [MarkupDocument] = []
    
    public func runIn(phase: LoadPhase) async -> Bool {
        return true
    }
    
    public mutating func add(_ doc: MarkupDocument) {
        markupDocs.append(doc)
    }
    
    public init(folderName: String) {
        self.folderName = folderName
    }
}
