//
// Imports.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public typealias ImportCallBack =  ((String) -> Void)

public protocol ImportsGathererCallBack {
    func addImport(type: String, file: String)
}

public class ImportsGatherer {
    public internal(set) var imports : ImportsGathererCallBack?
    public internal(set) var items : [CodeObject] = []
    
    public func add(_ item: CodeObject) {
        items.append(item)
    }
    
    public var debugDescription: String {
        return """
        \(self.items.count) items
        """
    }
    
    public init(@CodeObjectBuilder _ builder: () -> [CodeObject]) {
        self.items = builder()
    }
    
    public init(_ items: CodeObject...) {
        self.items = items
    }
    
    public init(_ items: [CodeObject]) {
        self.items = items
    }
    
    public init() {}
}
