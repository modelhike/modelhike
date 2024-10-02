//
// ModelRepository.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol ModelRepository {
    func loadModel(to model: AppModel) throws
    func processAfterLoad(model: AppModel, with ctx: Context) throws
    func loadGenerationConfigIfAny() throws
}

public extension ModelRepository {
    func processAfterLoad(model: AppModel, with ctx: Context) throws {
        //set specific port for each mobile
        var portNumber = 3000
        if ctx.variables.has(ModelConfigConstants.API_StartingPort) {
            if let value = ctx.variables[ModelConfigConstants.API_StartingPort] as? String {
                portNumber = Int(value) ?? portNumber
            }
        }
        
        model.containers.forEachComponent{  component in
            portNumber += 1
            component.attribs["port"] = "\(portNumber)"
        }
        
        //set dataType for each parsed type
        try model.commonModel.forEachType {  e, _ in e.dataType = .valueType }
        
        model.containers.forEachType {  e, component in
            
            if var cls = e as? DomainObject {
                if cls.givename.hasSuffix("Cache"){
                    e.dataType = .cache
                } else if cls.givename.hasSuffix("Input"){
                    e.dataType = .apiInput
                } else if cls.hasProp("_id") || cls.hasProp("id") {
                    e.dataType = .entity
                    
                    if e.hasNoAPIs() {
                        cls.appendAPI(.create)
                        cls.appendAPI(.update)
                        cls.appendAPI(.delete)
                        cls.appendAPI(.getById)
                        let getAll = cls.appendAPI(.list)
                        
                        if let getAllAnnotation = e.annotations["list"] {
                            if let mapping = getAllAnnotation as? MappingAnnotation {
                                for item in mapping.mappings {
                                    getAll[item.key] = item.value
                                }
                            }
                        }
                    }
                } else {
                    e.dataType = .embeddedType
                }
                return
            }
            
            if var cls = e as? DtoObject {
                if cls.givename.hasSuffix("Input"){
                    e.dataType = .apiInput
                } else {
                    e.dataType = .dto
                    
                    if e.hasNoAPIs() {
                        cls.appendAPI(.list)
                    }
                }
            }
        }
        
        
        print("💡 Loaded domain types: ", model.containers.types.count)
        print("💡 Loaded common types: ", model.commonModel.types.count)

    }
}
