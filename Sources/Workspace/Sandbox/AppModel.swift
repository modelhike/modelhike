//
// AppModel.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

open class AppModel {
    var types = ParsedTypesCache()
    public internal(set) var commonModel = C4ComponentList()
    private var modules = C4ComponentList()
    public internal(set) var containers = C4ContainerList()
    public internal(set) var isModelsLoaded = false

    public func resolveAndLinkItems(with ctx: LoadContext) throws {

        //resolve modules
        containers.forEach { container in
            for unresolvedMember in container.unresolvedMembers {
                if let module = module(named: unresolvedMember.name) {
                    container.append(module)
                    container.remove(unResolved: unresolvedMember)
                }
            }
        }
        
        commonModel.addTypesTo(model: types)
        containers.addTypesTo(model: types)
        
        //process types
        try containers.forEach { container in
            
            for type in container.types {
                try ParserUtil.extractMixins(for: type, with: ctx)
                
                if let dto = type as? DtoObject {
                    try dto.populateDerivedProperties()
                }
                
                //This should be done last, as the propeties for Dtos are populated only in the above steps
                for prop in type.properties {
                    if prop.type.isCustomType {
                        if let obj = ctx.model.types.get(for: prop.type.objectString()) {
                            //change the typename according to the retrieved object;
                            //this would correctly fix the type name, even if the given name
                            //has a diff character casing or had spaces
                            prop.type.kind = .customType(obj.name)
                        }
                    }
                }
            }
        }
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
