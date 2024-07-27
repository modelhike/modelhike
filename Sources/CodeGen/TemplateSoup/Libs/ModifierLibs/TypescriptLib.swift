//
// TypescriptLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TypescriptLib {
    public static var functions: [Modifier] {
        return [
            typename
        ]
    }
    
    
    public static var typename: Modifier {
        return CreateModifier.withoutParams("typename") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? TypeProperty_Wrap else {
              return "----ERROR----"
            }
            
            let prop = wrapped.item
            
            switch prop.type {
                case .int, .double : return "number"
                case .bool: return "boolean"
                case .string, .id: return "string"
                case .any: return "any"
                case .date: return "Date"
                case .buffer: return "Buffer"
                case .reference(_):
                    return "Reference"
                case .multiReference(_):
                    return "Reference"
                case .extendedReference(_):
                    return "ExtendedReference"
                case .multiExtendedReference(_):
                    return "ExtendedReference"
                case .codedValue(_):
                    return "CodedValue"
                case let .customType(typeName):
                    return typeName
                case .unKnown:
                    return "UnKnown"
            }
        }
    }
}
