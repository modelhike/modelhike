//
// TypescriptLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TypescriptLib {
    public static var functions: [Modifier] {
        return [
            typename,
            defaultValue
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
    
    public static var defaultValue: Modifier {
        return CreateModifier.withoutParams("defaultValue") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? TypeProperty_Wrap else {
              return "----ERROR----"
            }
            
            let prop = wrapped.item
            
            switch prop.type {
                case .int, .double : return "0"
                case .bool: return "false"
                case .id: return "\"\""
                case .string: return "null"
                case .any: return "null"
                case .date: return "Date"
                case .buffer: return "null"
                case .reference(_):
                    return "null"
                case .multiReference(_):
                    return "null"
                case .extendedReference(_):
                    return "null"
                case .multiExtendedReference(_):
                    return "null"
                case .codedValue(_):
                    return "null"
                case .customType(_):
                    return "null"
                case .unKnown:
                    return "UnKnown"
            }
        }
    }
}
