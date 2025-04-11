//
//  AppModel.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor AppModel {
    let types = ParsedTypesCache()
    public internal(set) var commonModel = C4ComponentList()
    private var modules = C4ComponentList()
    public internal(set) var containers = C4ContainerList()
    public internal(set) var isModelsLoaded = false

    public func resolveAndLinkItems(with ctx: LoadContext) async throws {

        //resolve modules
        await containers.forEach { container in
            for unresolvedMember in await container.unresolvedMembers {
                if let module = await module(named: unresolvedMember.name) {
                    await container.append(module)
                    await container.remove(unResolved: unresolvedMember)
                }
            }
        }
        
        commonModel.addTypesTo(model: types)
        await containers.addTypesTo(model: types)
        
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
    
    public func container(named name: String) async -> C4Container? {
        for container in containers {
            if await container.name == name {
                return container
            }
        }
        return nil
    }
    
    public func module(named name: String) async -> C4Component? {
        for module in modules {
            if await module.name == name {
                return module
            }
        }
        return nil
    }
    
    public func appendToCommonModel(contentsOf items: ModelSpace) async {
        let itemContainers = await items.containers
        
        for container in itemContainers {
            commonModel.append(contentsOf: container)
        }
    }
    
    public func append(contentsOf modelSpace: ModelSpace) async {
        let modelContainers = await modelSpace.containers
        let modelModules = await modelSpace.modules

        for item in modelContainers {
            containers.append(item)
        }
        
        for item in modelModules {
            modules.append(item)
        }
    }
    
    public init() {
        
    }

}
