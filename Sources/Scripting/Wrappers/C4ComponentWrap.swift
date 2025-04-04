//
//  C4Component_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor C4Component_Wrap : ObjectWrapper {
    public let item: C4Component
    let model : AppModel
    
    public var attribs: Attributes {
        get async { await item.attribs }
    }

    public var types: [CodeObject_Wrap] { get async {
        await item.types.compactMap({ CodeObject_Wrap($0)})
    }}
    
    public var embeddedTypes: [CodeObject_Wrap] { get async {
        var result: [CodeObject_Wrap] = []
        
        for type in await item.types {
            if await type.dataType == .embeddedType {
                result.append(CodeObject_Wrap(type))
            }
        }
        
        return result
    }}
    
    public var entities: [CodeObject_Wrap] { get async {
        var result: [CodeObject_Wrap] = []
        
        for type in await item.types {
            if await type.dataType == .entity {
                result.append(CodeObject_Wrap(type))
            }
        }
        
        return result
    }}
    
    public var dtos: [CodeObject_Wrap] {
        get async {
            var result: [CodeObject_Wrap] = []
            
            for type in await item.types {
                if await type.dataType == .dto, let dto = type as? DtoObject {
                    result.append(CodeObject_Wrap(dto))
                }
            }
            
            return result
        }
    }
    
    public var entitiesAndDtos : [CodeObject_Wrap] { get async {
        var list = await entities
        await list.append(contentsOf: dtos)
        return list
    }}
    
    public var apis: [API_Wrap] {
        get async {
            var result: [API_Wrap] = []
            
            for type in await item.types {
                let apis = await type.getAPIs()
                result.append(contentsOf: apis.compactMap { API_Wrap($0) })
            }
            
            return result
        }
    }
    
    public lazy var pushDataApis : [API_Wrap] = { self.apis.compactMap({
        if ($0.item.type == .pushData ||
            $0.item.type == .pushDataList 
        ) { return $0 } else {return nil}    }) }()
    
    public lazy var mutationApis : [API_Wrap] = { self.apis.compactMap({
        if ($0.item.type == .create ||
            $0.item.type == .update ||
            $0.item.type == .delete ||
            $0.item.type == .mutationUsingCustomLogic
            ) { return $0 } else {return nil}
    }) }()
    
    public lazy var queryApis : [API_Wrap] = { self.apis.compactMap({
        if ($0.item.type == .getById ||
            $0.item.type == .getByCustomProperties ||
            $0.item.type == .list ||
            $0.item.type == .listByCustomProperties 
        ) { return $0 } else {return nil}    }) }()
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) async throws -> Sendable {
        let value: Sendable = switch propname {
            case "name": item.name
            case "types" : types
            case "embedded-types" : embeddedTypes
            case "has-embedded-types" : embeddedTypes.count != 0
            case "entities" : entities
            case "has-entities" : entities.count != 0
            case "dtos" : dtos
            case "has-dtos" : dtos.count != 0
            case "entities-and-dtos" : entitiesAndDtos
            case "push-apis" : pushDataApis
            case "has-push-apis" : pushDataApis.count != 0
            case "query-apis" : queryApis
            case "has-query-apis" : queryApis.count != 0
            case "mutation-apis" : mutationApis
            case "has-mutation-apis" : mutationApis.count != 0
            case "has-any-apis" : apis.count != 0
           default:
            //nothing found; so check in module attributes
            let attribs = item.attribs  // Capture the actor reference
            if await attribs.has(propname) {
                await attribs[propname]
            } else {
                throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propname, pInfo)
            }
        }
        
        return value
    }
    
    public var debugDescription: String { item.debugDescription }

    public init(_ item: C4Component, model: AppModel ) {
        self.item = item
        self.model = model
    }
}





