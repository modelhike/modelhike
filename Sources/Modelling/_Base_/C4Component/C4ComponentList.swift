//
//  C4ComponentList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4ComponentList : ArtifactHolder, _CollectionAsyncSequence {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container
    
    public internal(set) var components : [C4Component] = []
    
    public func forEachType(by transform:  @Sendable (inout CodeObject, inout C4Component) async throws -> Void) async throws {
        for component in components {
            var component = component
            for type in await component.types {
                var type = type
                try await transform(&type, &component)
            }
        }
    }
    
    public func snapshot() -> [C4Component] {
        return components
    }
    
    public func forEach(by transform: @Sendable (inout C4Component) async throws -> Void) async throws {
        
        for el in components {
            var el = el
            try await transform(&el)
        }
    }
    
    public func addTypesTo(model appModel: ParsedTypesCache) async {
        for component in components {
            await appModel.append(component.types)
        }
    }
    
    public var types : [CodeObject] { get async {
        var list: [CodeObject] = []
        for item in components {
            await list.append(contentsOf: item.types)
        }
        return list
    }}
    
    public func append(_ item: C4Component) {
        components.append(item)
    }
    
    public func append(contentsOf newItems: [C4Component]) {
        self.components.append(contentsOf: newItems)
    }
    
    public func append(contentsOf item: C4Container) async {
        let itemComponent = await item.components.snapshot()
        self.components.append(contentsOf: itemComponent)
    }
    
    public func removeAll() {
        components.removeAll()
    }
    
    public var first: C4Component? { components.first }
    
    public var count: Int { components.count }
    
    public var debugDescription: String { get async {
        var str =  """
                    \(self.name)
                    items \(self.components.count):
                    """
        str += .newLine
        
        for item in components {
            let givenname = await item.givenname
            str += givenname + .newLine
        }
        
        return str
    }}
    
    public init(name: String = "", _ items: C4Component...) {
        self.name = name.normalizeForVariableName()
        self.givenname = name
        self.components = items
    }
    
    public init(name: String = "", _ items: [C4Component]) {
        self.name = name.normalizeForVariableName()
        self.givenname = name
        self.components = items
    }
    
    public init() {}
}

