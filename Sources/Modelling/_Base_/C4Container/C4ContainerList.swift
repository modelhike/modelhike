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

    public func addTypesTo(model appModel: ParsedTypesCache) async {
        for container in containers {
          await  container.components.addTypesTo(model: appModel)
        }
    }

    public func forEach(_ transform: @Sendable (inout C4Container) async throws -> Void) async rethrows {
        for el in containers {
            var el = el
            try await transform(&el)
        }
    }

    public func forEachComponent(_ transform: @Sendable (inout C4Component) async throws -> Void) async throws {
        for container in containers {
            try await container.components.forEach { el in
                try await transform(&el)
            }
        }
    }

    public func forEachType(_ transform: @Sendable (inout CodeObject, inout C4Component) async throws -> Void)
       async throws
    {
        for container in containers {
            try await container.components.forEachType { entity, component in
                try await transform(&entity, &component)
            }
        }
    }

    public var allComponents: [C4Component] {
        get async {
            return await containers.flatMap({ await $0.components.snapshot() })
        }
    }
    
    public var types: [CodeObject] {
        get async {
            return  await containers.flatMap({ await $0.types })
        }
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
