//
//  C4Component_Wrap.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class C4Component_Wrap : ObjectWrapper {
    public private(set) var item: C4Component
    var model : AppModel
    
    public var attribs: Attributes {
        get { item.attribs }
        set { item.attribs = newValue }
    }

    public lazy var types : [CodeObject_Wrap] = { item.types.compactMap({ CodeObject_Wrap($0)})
    }()
    
    public lazy var embeddedTypes : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .embeddedType {CodeObject_Wrap($0)} else {nil}})
    }()
    
    public lazy var entities : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .entity {CodeObject_Wrap($0)} else {nil}})
    }()
    
    public lazy var dtos : [CodeObject_Wrap] = { item.types.compactMap({
        if $0.dataType == .dto, let dto = $0 as? DtoObject {CodeObject_Wrap(dto)} else {nil}})
    }()
    
    public lazy var entitiesAndDtos : [CodeObject_Wrap] = {
        var list = entities
        list.append(contentsOf: dtos)
        return list
    }()
    
    public lazy var apis : [API_Wrap] = { item.types.flatMap({
        $0.getAPIs().compactMap({ API_Wrap($0) })
    }) }()
    
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
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        let value: Any = switch propname {
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
            if item.attribs.has(propname) {
                item.attribs[propname] as Any
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





