//
//  GraphQLLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct GraphQLLib {
    public static func functions() async -> [Modifier] {
        return await [
            typename()
        ]
    }

    
    public static func typename() async -> Modifier {
        return await CreateModifier.withoutParams("graphql-typename") { (value: Any, pInfo: ParsedInfo) -> String? in
            
            var type = PropertyKind.unKnown
            
            if let wrapped = value as? TypeProperty_Wrap {
                type = await wrapped.item.type.kind
            } else if let info = value as? TypeInfo {
                type = info.kind
            } else if let kind = value as? PropertyKind {
                type = kind
            } else {
                return "----ERROR----"
            }
            
            switch type {
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
