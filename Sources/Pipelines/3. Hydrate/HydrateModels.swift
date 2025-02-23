//
// HydrateModels.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public struct HydrateModelsPass  : LoadingPass {
    
    public func runIn(_ ws: Workspace, phase: LoadPhase) async throws -> Bool {
        try processAfterLoad(model: ws.model, with: ws.context)
            
        return true
    }
    
    func processAfterLoad(model: AppModel, with ctx: LoadContext) throws {
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
            
            if let cls = e as? DomainObject {
                if cls.givenname.hasSuffix("Cache"){
                    e.dataType = .cache
                } else if cls.givenname.hasSuffix("Input"){
                    e.dataType = .apiInput
                } else if cls.hasProp("_id") || cls.hasProp("id") {
                    e.dataType = .entity
                } else {
                    e.dataType = .embeddedType
                }
                return
            }
            
            if let cls = e as? DtoObject {
                if cls.givenname.hasSuffix("Input"){
                    e.dataType = .apiInput
                } else {
                    e.dataType = .dto
                }
            }
        }
    }
}
