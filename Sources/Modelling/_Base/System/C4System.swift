//
// C4System.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4System : ArtifactContainer {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public internal(set) var containers = C4ContainerList()
    
    public func append(_ item: C4Container) {
        containers.append(item)
    }
    
    public var count: Int { containers.count }
    
    public func removeAll() {
        containers.removeAll()
    }
    
    public var debugDescription: String {
        return """
        \(self.name)
        \(self.containers.count) items
        """
    }
    
    public init(name: String, items: C4Container...) {
        self.name = name
        self.containers.append(contentsOf: items)
    }
    
    public init(name: String, items: [C4Container]) {
        self.name = name
        self.containers.append(contentsOf: items)
    }
    
    public init(name: String, items: C4ContainerList) {
        self.name = name
        self.containers = items
    }
    
    internal init(){
        self.name = ""
    }
}
