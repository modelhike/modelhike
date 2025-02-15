//
// LoadContentFromFolder.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct LoadContentFromFolder : LoadingPass {
    public let folderName: String
    public let afterModifiedDate: Date?
    public var markupDocs: [MarkupDocument] = []
    
    public func runIn(phase: LoadPhase) async -> Bool {
        return true
    }
    
    public mutating func add(_ doc: MarkupDocument) {
        markupDocs.append(doc)
    }
    
    public init(folderName: String, afterModifiedDate: Date? = nil) {
        self.folderName = folderName
        self.afterModifiedDate = afterModifiedDate
    }
}
