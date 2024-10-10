//
// MockDataLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct MockDataLib {

    public static func functions(sandbox: Sandbox) -> [Modifier] {
        return [
            sampleJson(sandbox: sandbox),
            sampleQueryString(sandbox: sandbox),
            sampleValue(sandbox: sandbox)
        ]
    }
    
    private static func sampleJson(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("sample-json") { (value: Any, lineNo: Int) -> String? in
            
          guard let wrapped = value as? CodeObject_Wrap else {
            return nil
          }
          
          let obj = wrapped.item
          
          return SampleJson(entity: obj, typesModel: sandbox.model.types).string()
        }
    }

    private static func sampleValue(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("sample-value") { (value: Any, lineNo: Int) -> String? in
            
            var type = PropertyKind.unKnown
            var prefix = ""
            var suffix = ""
            var prop: Property?
            
            if let wrapped = value as? TypeProperty_Wrap {
                type = wrapped.item.type.kind
                prop = wrapped.item
            } else if let kind = value as? PropertyKind {
                type = kind
            } else {
                return "----ERROR----"
            }
            
            if let prop = prop {
                prefix = prop.type.isArray ? " [" : ""
                suffix = prop.type.isArray ? "]" : ""
            }
            
            let num = Int.random(in: 0..<100)
            let mocking = MockData_Generator()
            
            switch type {
                case .int, .double, .float :
                    return prefix + " \(num)" + suffix
                case .bool: return prefix + " true" + suffix
                case .string: 
                    if let prop = prop { //used for a property
                        return prefix + " \"\(prop.name) \(num)\"" + suffix
                    } else {
                        return prefix + " \"string \(num)\"" + suffix
                    }
                case .id: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
                case .date, .datetime: return prefix + " \"\(Date.now.ISO8601Format())\"" + suffix
                case .customType(let typename):
                    if let prop = prop { //used for a property
                        if let obj = sandbox.model.types.get(for: prop.type.objectString()) {
                            return SampleJson(entity: obj, typesModel: sandbox.model.types)
                                .string(openCloseBraces: true, openCloseQuotesInNames: false)
                        } else { return "" }
                    } else {
                        if let obj = sandbox.model.types.get(for: typename) {
                            return SampleJson(entity: obj, typesModel: sandbox.model.types)
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
                        if let obj = sandbox.model.types.get(for: prop.type.objectString()) {
                            return SampleJson(entity: obj, typesModel: sandbox.model.types)
                                .string(openCloseBraces: true, openCloseQuotesInNames: false)
                        } else { return "" }
                    } else {
                        return ""
                    }
            }
        }
    }
        
    private static func sampleQueryString(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("sample-query") { (value: Any, lineNo: Int) -> String? in
            
          guard let wrapped = value as? API_Wrap else {
            return nil
          }
          
          let obj = wrapped.item
          
          return SampleQueryString(api: obj, typesModel: sandbox.model.types).string
        }
    }
}
