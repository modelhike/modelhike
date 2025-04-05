//
//  C4ContainerList.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4ContainerList: ArtifactHolder, _CollectionAsyncSequence {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var containers: [C4Container] = []
    private var currentIndex = 0

    public func addTypesTo(model appModel: ParsedTypesCache) {
        for container in containers {
            container.components.addTypesTo(model: appModel)
        }
    }

    public func forEach(_ transform: (inout C4Container) async throws -> Void) async rethrows {
        for el in containers {
            var el = el
            try await transform(&el)
        }
    }

    public func forEachComponent(_ transform: (inout C4Component) throws -> Void) rethrows {
        for container in containers {
            try container.components.forEach { el in
                try transform(&el)
            }
        }
    }

    public func forEachType(_ transform: (inout CodeObject, inout C4Component) throws -> Void)
        rethrows
    {
        _ = try containers.map { container in
            try container.components.forEachType { entity, component in
                try transform(&entity, &component)
            }
        }
    }

    public var types: [CodeObject] {
        return containers.flatMap({ $0.types })
    }

    public var first: C4Container? { containers.first }

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

    public func snapshot() -> [C4Container] {
        return containers
    }
    
    public var debugDescription: String { get async {
        var str = """
            \(self.name)
            containers \(self.containers.count):
            """
        str += .newLine
        
        for item in containers {
            let givenname = await item.givenname
            str += givenname + .newLine
            
        }
        
        return str
    }}

    public init(name: String = "", _ items: C4Container...) {
        self.name = name
        self.givenname = name
        self.containers = items
    }

    public init(name: String = "", _ items: [C4Container]) {
        self.name = name
        self.givenname = name
        self.containers = items
    }

    public init() {}
}
