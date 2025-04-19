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
    public private(set) var containers = C4ContainerList()
    public private(set) var isModelsLoaded = false

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
        
        await commonModel.addTypesTo(model: types)
        await containers.addTypesTo(model: types)
        
        //process types
        try await containers.forEach { container in
            
            for type in await container.types {
                try await ParserUtil.extractMixins(for: type, with: ctx)
                
                if let dto = type as? DtoObject {
                    try await dto.populateDerivedProperties()
                }
                
                //This should be done last, as the propeties for Dtos are populated only in the above steps
                for prop in await type.properties {
                    if await prop.type.isCustomType {
                        if let obj = await ctx.model.types.get(for: prop.type.objectString()) {
                            //change the typename according to the retrieved object;
                            //this would correctly fix the type name, even if the given name
                            //has a diff character casing or had spaces
                            await prop.typeKind( .customType(obj.name))
                        }
                    }
                }
            }
        }
    }
    
    public func container(named name: String) async -> C4Container? {
        return await containers.first(where: {await $0.name == name})
    }
    
    public func module(named name: String) async -> C4Component? {
        return await modules.first(where: {await $0.name == name})
    }
    
    public func appendToCommonModel(contentsOf items: ModelSpace) async {
        let itemContainers = await items.containers
        
        for await container in itemContainers {
            await commonModel.append(contentsOf: container)
        }
    }
    
    public func append(contentsOf modelSpace: ModelSpace) async {
        let modelContainers = await modelSpace.containers.snapshot()
        let modelModules = await modelSpace.modules.snapshot()

        for item in modelContainers {
            await containers.append(item)
        }
        
        for item in modelModules {
            await modules.append(item)
        }
    }
    
    internal func isModelsLoaded(_ value: Bool) {
        self.isModelsLoaded = value
    }
    
    public init() {
        
    }

}
