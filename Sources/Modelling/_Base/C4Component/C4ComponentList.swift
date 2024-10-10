//
// C4ComponentList.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4ComponentList : ArtifactContainer, IteratorProtocol, Sequence {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var components : [C4Component] = []
    private var currentIndex = 0

    public func forEachType(by transform: (inout CodeObject, inout C4Component) throws -> Void) throws {
        try components.forEach { item in
            try item.types.forEach { e in try transform(&e, &item) }
        }
     }
    
    public func forEach(by transform: (inout C4Component) throws -> Void) rethrows {
        _ = try components.map { el in
            var el = el
            try transform(&el)
            return el
        }
    }
    
    public func next() -> C4Component? {
        if currentIndex <= components.count - 1 {
            let compo = components[currentIndex]
            currentIndex += 1
            return compo
        } else {
            currentIndex = 0 //reset index
            return nil
        }
    }
    
    public func addTypesTo(model appModel: ParsedTypesCache) {
        for component in components {
            appModel.append(component.types)
        }
    }
    
    public var types : [CodeObject] {
        return components.flatMap({ $0.types })
    }
    
    public func append(_ item: C4Component) {
        components.append(item)
    }
    
    public func append(contentsOf newItems: [C4Component]) {
        self.components.append(contentsOf: newItems)
    }
    
    public func append(contentsOf item: C4Container) {
        self.components.append(contentsOf: item.components)
    }
    
    public func removeAll() {
        components.removeAll()
    }
    
    public var first: C4Component? { components.first }
    
    public var count: Int { components.count }
    
    public var debugDescription: String {
        var str =  """
                    \(self.name)
                    items \(self.components.count):
                    """
        str += .newLine

        for item in components {
            str += item.givenname + .newLine
            
        }
        
        return str
    }
    
    public init(name: String = "", _ items: C4Component...) {
        self.name = name
        self.givenname = name
        self.components = items
    }
    
    public init(name: String = "", _ items: [C4Component]) {
        self.name = name
        self.givenname = name
        self.components = items
    }
    
    public init() {}
}

