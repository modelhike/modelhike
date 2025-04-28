//
//  C4System.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4System: ArtifactHolder {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var containers = C4ContainerList()

    public func append(_ item: C4Container) async {
        await containers.append(item)
    }

    public var count: Int { get async { await containers.count }}

    public func removeAll() async {
        await containers.removeAll()
    }

    public var debugDescription: String { get async {
        var str = """
            \(self.name)
            containers \(await self.containers.count):
            """
        str += .newLine
        
        for item in await containers.snapshot() {
            await str += item.givenname + .newLine
            
        }
        
        return str
    }}

    public init(name: String, items: C4Container...) async {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        await self.containers.append(contentsOf: items)
    }

    public init(name: String, items: [C4Container]) async {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        await self.containers.append(contentsOf: items)
    }

    public init(name: String, items: C4ContainerList) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containers = items
    }

    internal init() {
        self.name = ""
        self.givenname = ""
    }
}
