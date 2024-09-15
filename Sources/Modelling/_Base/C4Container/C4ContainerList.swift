//
// C4ContainerList.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4ContainerList : ArtifactContainer, IteratorProtocol, Sequence {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public var name: String = ""
    public internal(set) var containers : [C4Container] = []
    private var currentIndex = 0
    
    public func addTypesTo(model appModel: ParsedModelCache) {
        for container in containers {
            container.components.addTypesTo(model: appModel)
        }
    }
    
    public func forEach(_ transform: (inout C4Container) throws -> Void) rethrows {
        _ = try containers.map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
    
    public func forEachComponent(_ transform: (inout C4Component) throws -> Void) rethrows {
        _ = try containers.map { container in
                try container.components.forEach { el in
                    try transform(&el)
                }
        }
    }
    
    public func forEachEntity(_ transform: (inout CodeObject, inout C4Component) throws -> Void) rethrows {
        _ = try containers.map { container in
            try container.components.forEachEntity{ entity, component in
                try transform(&entity, &component)
            }
        }
    }
    
    public func getEntities() -> [CodeObject] {
        return containers.flatMap({ $0.getEntities() })
    }
    
    public func next() -> C4Container? {
        if currentIndex <= containers.count - 1 {
            let compo = containers[currentIndex]
            currentIndex += 1
            return compo
        } else {
            currentIndex = 0 //reset index
            return nil
        }
    }
    
    public var first : C4Container? { containers.first }
    
    public func append(_ item: C4Container) {
        containers.append(item)
    }
    
    public func append(contentsOf newItems: [C4Container]) {
        self.containers.append(contentsOf: newItems)
    }
    
    public func removeAll() {
        containers.removeAll()
    }
    
    public var count: Int { containers.count }
    
    public var debugDescription: String {
        return """
        \(self.name)
        \(self.containers.count) items
        """
    }
    
    public init(name: String = "", _ items: C4Container...) {
        self.name = name
        self.containers = items
    }
    
    public init(name: String = "", _ items: [C4Container]) {
        self.name = name
        self.containers = items
    }
    
    public init() {}
}
