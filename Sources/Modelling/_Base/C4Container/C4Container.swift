//
// C4Container.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class C4Container : ArtifactContainer {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public internal(set) var components = C4ComponentList()
    public internal(set) var unresolvedMembers: [ContainerModuleMember] = []

    public func toDictionary(using appModel: AppModel) -> [String: Any] {
        let dict: [String: Any] = [
            "model": appModel.parsedModel,
            "modules" : components(self.components, appModel: appModel),
            "commons" : components(appModel.commonModel, appModel: appModel),
            "module-default" : getFirstModule(appModel: appModel) as Any,
            "mock" : Mocking_Wrap()
        ]
        return dict
    }
    
    public func getEntities() -> [CodeObject] {
        return components.getEntities()
    }
    
    private func components(_ items: C4ComponentList, appModel: AppModel) -> [C4Component_Wrap]  { return items.compactMap({ C4Component_Wrap($0, model: appModel)})
    }
    
    private func getFirstModule(appModel: AppModel) -> C4Component_Wrap? {
        return (self.components.first != nil) ? C4Component_Wrap(self.components.first!, model: appModel) : nil
    }
    
    public func append(unResolved item: ContainerModuleMember) {
        unresolvedMembers.append(item)
    }
    
    public func remove(unResolved item: ContainerModuleMember) {
        unresolvedMembers.removeAll(where: { $0.name == item.name })
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
        return """
        \(self.name)
        \(self.components.count) components
        """
    }
    
    public init(name: String, items: C4Component...) {
        self.name = name
        self.components.append(contentsOf: items)
    }
    
    public init(name: String, items: [C4Component]) {
        self.name = name
        self.components.append(contentsOf: items)
    }
    
    public init(name: String, items: C4ComponentList) {
        self.name = name
        self.components = items
    }
    
    internal init() {
        self.name = ""
    }
}
