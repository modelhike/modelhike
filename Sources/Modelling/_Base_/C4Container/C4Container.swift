//
//  C4Container.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Container : ArtifactHolder {
    public let attribs = Attributes()
    public let tags = Tags()
    public let annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public var containerType: ContainerKind

    public var components = C4ComponentList()
    public private(set) var unresolvedMembers: [ContainerModuleMember] = []
    public private(set) var methods: [MethodObject] = []
    
    public var types : [CodeObject] {
        get async {
            return await components.types
        }
    }
    
    func components(_ items: C4ComponentList, appModel: AppModel) async -> [C4Component_Wrap] {
        return await items.snapshot().compactMap({ C4Component_Wrap($0, model: appModel)})
    }
    
    func getFirstModule(appModel: AppModel) async -> C4Component_Wrap? {
        if let first = await components.first {
            return C4Component_Wrap(first, model: appModel)
        } else {
            return nil
        }
    }
    
    public func append(unResolved item: ContainerModuleMember) {
        unresolvedMembers.append(item)
    }
    
    public func remove(unResolved item: ContainerModuleMember) async {
        let targetName = item.name
        unresolvedMembers.removeAll(where: { $0.name == targetName })
    }
    
    public func append(_ item: MethodObject) {
        methods.append(item)
    }
    
    public func append(_ item: C4Component) async {
        await components.append(item)
    }
    
    public var isEmpty: Bool { get async { await components.count == 0 } }
    
    public var first : C4Component? { get async { await components.first } }


    public var count: Int { get async { await components.count } }
    
    public func removeAll() async {
        await components.removeAll()
    }
    
    public var debugDescription: String {
        get async {
            var str =  """
                    \(self.name)
                    | components \(await self.components.count):
                    """
            str += .newLine
            
            for item in await components.snapshot() {
                await str += "| " + item.givenname + .newLine
            }
            
            return str
        }
    }
    
    public init(name: String, type: ContainerKind = .unKnown, items: C4Component...) async {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
       await self.components.append(contentsOf: items)
    }
    
    public init(name: String, type: ContainerKind = .unKnown, items: [C4Component]) async {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
       await self.components.append(contentsOf: items)
    }
    
    public init(name: String, type: ContainerKind = .unKnown, items: C4ComponentList) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
        self.components = items
    }
    
    public init(name: String, type: ContainerKind = .unKnown) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
    }
    
    internal init() {
        self.name = ""
        self.givenname = ""
        self.containerType = .unKnown
    }
}


public enum ContainerKind : Equatable {
    case unKnown, microservices, webApp, mobileApp
}
