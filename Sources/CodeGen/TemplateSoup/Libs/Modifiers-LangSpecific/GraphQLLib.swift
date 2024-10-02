//
// GraphQLLib.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct GraphQLLib {
    public static var functions: [Modifier] {
        return [
            typename
        ]
    }
    
    
    public static var typename: Modifier {
        return CreateModifier.withoutParams("graphql-typename") { (value: Any, lineNo: Int) -> String? in
            
            guard let wrapped = value as? TypeProperty_Wrap else {
                return "----ERROR----"
            }
            
            let prop = wrapped.item
            
            switch prop.type {
                case .int : return "Int"
                case .float, .double : return "Float"
                case .bool: return "Boolean"
                case .string: return "String"
                case .id: return "ID"
                case .any: return "Object"
                case .date: return "Date"
                case .datetime: return "DateTime"
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
    
}
