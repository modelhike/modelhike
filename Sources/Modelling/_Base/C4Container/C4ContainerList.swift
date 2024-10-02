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
    public var givename: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var containers : [C4Container] = []
    private var currentIndex = 0
    
    public func addTypesTo(model appModel: ParsedTypesCache) {
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
    
    public func forEachType(_ transform: (inout CodeObject, inout C4Component) throws -> Void) rethrows {
        _ = try containers.map { container in
            try container.components.forEachType{ entity, component in
                try transform(&entity, &component)
            }
        }
    }
    
    public var types : [CodeObject] {
        return containers.flatMap({ $0.types })
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
        var str =  """
                    \(self.name)
                    containers \(self.containers.count):
                    """
        str += .newLine

        for item in containers {
            str += item.givename + .newLine
            
        }
        
        return str
    }
    
    public init(name: String = "", _ items: C4Container...) {
        self.name = name
        self.givename = name
        self.containers = items
    }
    
    public init(name: String = "", _ items: [C4Container]) {
        self.name = name
        self.givename = name
        self.containers = items
    }
    
    public init() {}
}
