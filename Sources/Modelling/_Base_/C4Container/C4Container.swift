//
//  C4Container.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Container : ArtifactHolder {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public var containerType: ContainerKind

    public let components = C4ComponentList()
    public internal(set) var unresolvedMembers: [ContainerModuleMember] = []
    public internal(set) var methods: [MethodObject] = []
    
    public var types : [CodeObject] {
        return components.types
    }
    
    func components(_ items: C4ComponentList, appModel: AppModel) -> [C4Component_Wrap]  { return items.compactMap({ C4Component_Wrap($0, model: appModel)})
    }
    
    func getFirstModule(appModel: AppModel) -> C4Component_Wrap? {
        return (self.components.first != nil) ? C4Component_Wrap(self.components.first!, model: appModel) : nil
    }
    
    public func append(unResolved item: ContainerModuleMember) {
        unresolvedMembers.append(item)
    }
    
    public func remove(unResolved item: ContainerModuleMember) {
        unresolvedMembers.removeAll(where: { $0.name == item.name })
    }
    
    public func append(_ item: MethodObject) {
        methods.append(item)
    }
    
    public func append(_ item: C4Component) {
        components.append(item)
    }
    
    public var isEmpty: Bool { components.count == 0 }

    public var first : C4Component? { components.first }

    public var count: Int { components.count }
    
    public func removeAll() {
        components.removeAll()
    }
    
    public var debugDescription: String {
        var str =  """
                    \(self.name)
                    | components \(self.components.count):
                    """
        str += .newLine

        for item in components {
            str += "| " + item.givenname + .newLine
        }
        
        return str
    }
    
    public init(name: String, type: ContainerKind = .unKnown, items: C4Component...) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
        self.components.append(contentsOf: items)
    }
    
    public init(name: String, type: ContainerKind = .unKnown, items: [C4Component]) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.containerType = type
        self.components.append(contentsOf: items)
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
