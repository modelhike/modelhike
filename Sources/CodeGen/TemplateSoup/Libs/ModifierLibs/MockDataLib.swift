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
          
          return SampleJson(entity: obj, appModel: sandbox.model.parsedModel).string
        }
    }

    private static func sampleValue(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("sample-value") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? TypeProperty_Wrap else {
                return nil
            }
            
            let prop = wrapped.item
            
            let prefix = prop.isArray ? " [" : ""
            let suffix = prop.isArray ? "]" : ""
            
            let num = Int.random(in: 0..<100)
            let mocking = MockData_Generator()
            
            switch prop.type {
                case .int, .double, .float :
                    return prefix + " \(num)" + suffix
                case .bool: return prefix + " true" + suffix
                case .string: return prefix + " \"\(prop.name) \(num)\"" + suffix
                case .id: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
                case .any: return prefix + " \"" + mocking.randomObjectId_MongoDb() + "\"" + suffix
                case .date: return prefix + " \"\(Date.now.ISO8601Format())\"" + suffix
                default : return ""
            }
        }
    }
        
    private static func sampleQueryString(sandbox: Sandbox) -> Modifier {
        return CreateModifier.withoutParams("sample-query") { (value: Any, lineNo: Int) -> String? in
            
          guard let wrapped = value as? API_Wrap else {
            return nil
          }
          
          let obj = wrapped.item
          
          return SampleQueryString(api: obj, appModel: sandbox.model.parsedModel).string
        }
    }
}
