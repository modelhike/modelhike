//
// AppModel.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class AppModel {
    var parsedModel = ParsedModelCache()
    public internal(set) var commonModel = C4ComponentList()
    private var modules = C4ComponentList()
    public internal(set) var containers = C4ContainerList()
    
    public func resolveAndLinkItems() {

        containers.forEach { container in
            for unresolvedMember in container.unresolvedMembers {
                if let module = module(named: unresolvedMember.name) {
                    container.append(module)
                    container.remove(unResolved: unresolvedMember)
                }
            }
        }
        
        commonModel.addTypesTo(model: parsedModel)
        containers.addTypesTo(model: parsedModel)
    }
    
    public func container(named name: String) -> C4Container? {
        return containers.first(where: {$0.name == name})
    }
    
    public func module(named name: String) -> C4Component? {
        return modules.first(where: {$0.name == name})
    }
    
    public func appendToCommonModel(contentsOf items: ModelSpace) {
        for container in items.containers {
            commonModel.append(contentsOf: container)
        }
    }
    
    public func append(contentsOf modelSpace: ModelSpace) {
        for item in modelSpace.containers {
            containers.append(item)
        }
        
        for item in modelSpace.modules {
            modules.append(item)
        }
    }
    
    public init() {
        
    }

}
