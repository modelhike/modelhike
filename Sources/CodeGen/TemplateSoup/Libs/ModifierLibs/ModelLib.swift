//
// ModelLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ModelLib {
    public static func functions(sandbox: Sandbox) -> [Modifier] {
        return [
            getObjectWithName(sandbox: sandbox),
            getLastRecursivePropWithName(sandbox: sandbox),
            getAPIsforEntity(sandbox: sandbox)
        ]
    }
    
    public static func getObjectWithName(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("get-object") { (objectName: String, lineNo: Int) -> CodeObject_Wrap? in
            
            if let obj = sandbox.model.parsedModel.get(for: objectName) {
                return CodeObject_Wrap(obj)
            } else { return nil }
        }
    }
    
    public static func getLastRecursivePropWithName(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withParams("get-last-recursive-prop") { (propName: String, arguments: [Any], lineNo: Int) -> TypeProperty_Wrap? in
            
            guard let objectName = arguments.first as? String else { return nil }
            
            let appModel = sandbox.model.parsedModel
            if let obj = appModel.get(for: objectName) {
                if let prop = obj.getLastPropInRecursive(propName, appModel: appModel) {
                    return TypeProperty_Wrap(prop)
                }
            }
            
            return nil
        }
    }
    
    public static func getAPIsforEntity(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withParams("apis-for") { (module: Any, arguments: [Any], lineNo: Int) -> [API_Wrap] in
            
            guard let entityName = arguments.first as? String
                                                                else { return [] }

            if let module = module as? C4Component_Wrap,
               let entity = sandbox.model.parsedModel.get(for: entityName) {
                let apis = module.item.getAPIsFor(entity: entity)
                return apis.compactMap({ API_Wrap($0) })
            } else { return [] }
        }
    }
}
