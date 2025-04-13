//
//  ModelLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ModelLib {
    public static func functions(sandbox: Sandbox) async -> [Modifier] {
        return await [
            getObjectWithName(sandbox: sandbox),
            getLastRecursivePropWithName(sandbox: sandbox),
            getAPIsforCodeObject(sandbox: sandbox),
        ]
    }

    public static func getObjectWithName(sandbox: Sandbox) async -> Modifier {
        return CreateModifier.withoutParams("get-object") {
            (objectName: String, pInfo: ParsedInfo) throws -> CodeObject_Wrap? in

            if let obj = await sandbox.model.types.get(for: objectName) {
                return CodeObject_Wrap(obj)
            } else {
                throw TemplateSoup_ParsingError.objectTypeNotFound(objectName, pInfo)
            }
        }
    }

    public static func getLastRecursivePropWithName(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withParams("get-last-recursive-prop") {
            (propName: String, arguments: [Any], pInfo: ParsedInfo) throws -> TypeProperty_Wrap? in

            guard let objectName = arguments.first as? String else { return nil }

            let appModel = sandbox.model.types
            if let obj = await appModel.get(for: objectName) {
                if let prop = await obj.getLastPropInRecursive(propName, appModel: appModel) {
                    return TypeProperty_Wrap(prop)
                }
            }

            throw TemplateSoup_ParsingError.invalidPropertyNameUsedInCall(propName, pInfo)
        }
    }

    public static func getAPIsforCodeObject(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withoutParams("apis") {
            (entity: Any, pInfo: ParsedInfo) -> [API_Wrap] in

            if let entityName = entity as? String,
               let entity = await sandbox.model.types.get(for: entityName)
            {
                let apis = await entity.getAPIs()
                return apis.compactMap({ API_Wrap($0) })
            } else if let objWrap = entity as? CodeObject_Wrap {
                let apis = await objWrap.item.getAPIs()
                return apis.compactMap({ API_Wrap($0) })
            } else {
                return []
            }
        }
    }
}
