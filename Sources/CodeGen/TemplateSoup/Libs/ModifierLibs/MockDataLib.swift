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
            sampleQueryString(sandbox: sandbox)
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
