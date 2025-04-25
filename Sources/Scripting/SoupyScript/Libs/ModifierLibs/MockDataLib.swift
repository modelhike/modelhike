//
//  MockDataLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct MockDataLib {

    public static func functions(sandbox: Sandbox) async -> [Modifier] {
        return await [
            sampleJson(sandbox: sandbox),
            sampleQueryString(sandbox: sandbox),
            sampleValue(sandbox: sandbox)
        ]
    }
    
    private static func sampleJson(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withoutParams("sample-json") { (value: Sendable, pInfo: ParsedInfo) -> String? in
            
          guard let wrapped = value as? CodeObject_Wrap else {
            return nil
          }
          
          let obj = wrapped.item
          
            return await SampleJson(entity: obj, typesModel: sandbox.model.types).string()
        }
    }

    private static func sampleValue(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withoutParams("sample-value") { (value: Sendable, pInfo: ParsedInfo) -> String? in
            
            var type = PropertyKind.unKnown
            var prefix = ""
            var suffix = ""
            var prop: Property?
            
            if let wrapped = value as? TypeProperty_Wrap {
                type = await wrapped.item.type.kind
                prop = wrapped.item
            } else if let kind = value as? PropertyKind {
                type = kind
            } else {
                return "----ERROR----"
            }
            
            if let prop = prop {
                prefix = await prop.type.isArray ? " [" : ""
                suffix = await prop.type.isArray ? "]" : ""
            }
            
            let num = Int.random(in: 0..<100)
            let mocking = MockData_Generator()
            
            switch type {
                case .int, .double, .float :
                    return prefix + " \(num)" + suffix
                case .bool: return prefix + " true" + suffix
                case .string: 
                    if let prop = prop { //used for a property
                        return prefix + " \"\(await prop.name) \(num)\"" + suffix
                    } else {
                        return prefix + " \"string \(num)\"" + suffix
                    }
                case .id: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
                case .date, .datetime: return prefix + " \"\(Date.now.ISO8601Format())\"" + suffix
                case .customType(let typename):
                    if let prop = prop { //used for a property
                        if let obj = await sandbox.model.types.get(for: prop.type.objectString()) {
                            return await SampleJson(entity: obj, typesModel: sandbox.model.types)
                                .string(openCloseBraces: true, openCloseQuotesInNames: false)
                        } else { return "" }
                    } else {
                        if let obj = await sandbox.model.types.get(for: typename) {
                            return await SampleJson(entity: obj, typesModel: sandbox.model.types)
                                .string(openCloseBraces: true, openCloseQuotesInNames: false)
                        } else { return "" }
                    }
                case .buffer:
                    return "[]"
                case .any:
                    return ""
                case .unKnown:
                    return "----ERROR-------"
                default:
                    if let prop = prop { //used for a property
                        if let obj = await sandbox.model.types.get(for: prop.type.objectString()) {
                            return await SampleJson(entity: obj, typesModel: sandbox.model.types)
                                .string(openCloseBraces: true, openCloseQuotesInNames: false)
                        } else { return "" }
                    } else {
                        return ""
                    }
            }
        }
    }
        
    private static func sampleQueryString(sandbox: Sandbox) async -> Modifier {
        return await CreateModifier.withoutParams("sample-query") { (value: Sendable, pInfo: ParsedInfo) -> String? in
            
          guard let wrapped = value as? API_Wrap else {
            return nil
          }
          
          let obj = wrapped.item
          
            return await SampleQueryString(api: obj, typesModel: sandbox.model.types).string
        }
    }
}
