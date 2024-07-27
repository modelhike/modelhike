//
// C4Component.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4Component : ArtifactContainer {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public internal(set) var items : [Artifact] = []
    public internal(set) var types : [CodeObject] = []
    
    public func forEachEntity(by process: (CodeObject) throws -> Void) throws {
        for item in types {
            if item.dataType == .entity { try process(item) }
        }
     }
    
    public func append(_ item: CodeObject) {
        items.append(item)
        types.append(item)
    }
    
    public func append(_ item: C4Component) {
        items.append(item)
    }
    
    public var isEmpty: Bool { items.count == 0 }
    
    public var debugDescription: String {
        return """
        \(self.name)
        \(self.items.count) items
        """
    }
    
    public init(name: String = "", @ArtifactContainerBuilder _ builder: () -> [ArtifactContainer]) {
        self.name = name
        self.items = builder()
    }
    
    public init(name: String = "", _ items: ArtifactContainer...) {
        self.name = name
        self.items = items
    }
    
    public init(name: String = "", _ items: [ArtifactContainer]) {
        self.name = name
        self.items = items
    }
    
    public init(name: String) {
        self.name = name
        self.items = []
    }
    
    public init(name: Substring) {
        self.name = String(name)
        self.items = []
    }
    
    public init() {}
}
