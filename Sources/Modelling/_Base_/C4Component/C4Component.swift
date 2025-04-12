//
//  C4Component.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Component : ArtifactHolder {
    public let attribs = Attributes()
    public let tags = Tags()
    public let annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public internal(set) var items : [Artifact] = []
    public internal(set) var types : [CodeObject] = []
    
    public func forEachEntity(by process: (CodeObject) throws -> Void) async throws {
        for item in types {
            if await item.dataType == .entity { try process(item) }
        }
     }
    
    public func append(_ item: CodeObject) {
        items.append(item)
        types.append(item)
    }
    
    public func append(_ item: UIObject) {
        items.append(item)
    }
    
    public func append(submodule item: C4Component) {
        items.append(item)
    }
    
    public var isEmpty: Bool { items.count == 0 }
    
    public nonisolated var debugDescription: String {
        get async {
            let name = await self.name
            let count = await self.items.count
            
            var str =  """
                    \(name)
                    | items \(count):
                    """
            str += .newLine
            
            for item in await items {
                let givenname = await item.givenname
                str += "| " + givenname + .newLine
                
            }
            
            return str
        }
    }
    
    public init(name: String = "", @ArtifactHolderBuilder _ builder: () -> [ArtifactHolder]) {
        self.name = name.trim()
        self.givenname = self.name
        self.items = builder()
    }
    
    public init(name: String = "", _ items: ArtifactHolder...) {
        self.name = name.trim()
        self.givenname = self.name
        self.items = items
    }
    
    public init(name: String = "", _ items: [ArtifactHolder]) {
        self.name = name.trim()
        self.givenname = self.name
        self.items = items
    }
    
    public init(name: String) {
        self.name = name.trim()
        self.givenname = self.name
        self.items = []
    }
    
    public init(name: Substring) {
        self.name = String(name).trim()
        self.givenname = self.name
        self.items = []
    }
    
    public init() {}
}
