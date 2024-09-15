//
// ModelRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol ModelRepository {
    func loadModel(to model: AppModel) throws
    func didLoad(model: AppModel) throws
}

public extension ModelRepository {
    func didLoad(model: AppModel) throws {
        var portNumber = 3000

        try model.commonModel.forEachEntity {  e, _ in e.dataType = .valueType }
        model.containers.forEachComponent{  component in
            portNumber += 1
            component.attribs["port"] = "\(portNumber)"
        }
        
        model.containers.forEachEntity {  e, component in
            
            if let cls = e as? DomainObject {
                if cls.givename.hasSuffix("Cache"){
                    e.dataType = .cache
                } else if cls.givename.hasSuffix("Dto"){
                    e.dataType = .dto
                } else if cls.hasProp("_id") || cls.hasProp("id") {
                    e.dataType = .entity
                    
                    component.appendAPI(.create, for: cls)
                    component.appendAPI(.update, for: cls)
                    component.appendAPI(.delete, for: cls)
                    component.appendAPI(.getById, for: cls)
                    let getAll = component.appendAPI(.list, for: cls)
                    
                    if let getAllAnnotation = e.annotations["list"] {
                        if let mapping = getAllAnnotation as? MappingAnnotation {
                            for item in mapping.mappings {
                                getAll[item.key] = item.value
                            }
                        }
                    }
                    
                } else {
                    e.dataType = .embeddedType
                }
            }
        }
        
        
        print("💡 Loaded domain entities: ", model.containers.getEntities().count)
        print("💡 Loaded common models: ", model.commonModel.getEntities().count)

    }
}
