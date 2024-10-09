//
// JavaLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct JavaLib {
    public static var functions: [Modifier] {
        return [
            typename,
            defaultValue
        ]
    }
    
    
    public static var typename: Modifier {
        return CreateModifier.withoutParams("typename") { (value: Any, lineNo: Int) -> String? in
            var type = PropertyKind.unKnown
            
            if let wrapped = value as? TypeProperty_Wrap {
                type = wrapped.item.type
            } else if let kind = value as? PropertyKind {
                type = kind
            } else {
                return "----ERROR----"
            }
                        
            switch type {
                case .int : return "Integer"
                case .float : return "Float"
                case .double : return "Double"
                case .bool: return "Boolean"
                case .string, .id: return "String"
                case .any: return "Object"
                case .date, .datetime: return "Date"
                case .buffer: return "Byte[]"
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
        return CreateModifier.withoutParams("default-value") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? TypeProperty_Wrap else {
              return "----ERROR----"
            }
            
            let prop = wrapped.item
            
            switch prop.type {
                case .int, .double, .float : return "0"
                case .bool: return "false"
                case .id: return "\"\""
                case .string: return "null"
                case .any: return "null"
                case .date, .datetime: return "new Date()"
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
