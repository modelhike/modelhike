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
            getAPIsforCodeObject(sandbox: sandbox)
        ]
    }
    
    public static func getObjectWithName(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("get-object") { (objectName: String, lineNo: Int) -> CodeObject_Wrap? in
            
            if let obj = sandbox.model.types.get(for: objectName) {
                return CodeObject_Wrap(obj)
            } else { return nil }
        }
    }
    
    public static func getLastRecursivePropWithName(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withParams("get-last-recursive-prop") { (propName: String, arguments: [Any], lineNo: Int) -> TypeProperty_Wrap? in
            
            guard let objectName = arguments.first as? String else { return nil }
            
            let appModel = sandbox.model.types
            if let obj = appModel.get(for: objectName) {
                if let prop = obj.getLastPropInRecursive(propName, appModel: appModel) {
                    return TypeProperty_Wrap(prop)
                }
            }
            
            return nil
        }
    }
    
    public static func getAPIsforCodeObject(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("apis") { (entity: Any, lineNo: Int) -> [API_Wrap] in

            if let entityName = entity as? String,
               let entity = sandbox.model.types.get(for: entityName) {
                let apis = entity.getAPIs()
                return apis.compactMap({ API_Wrap($0) })
            } else if let entity = entity as? CodeObject_Wrap {
                let apis = entity.item.getAPIs()
                return apis.compactMap({ API_Wrap($0) })
            } else { return [] }
        }
    }
}
