//
//  JavaLib.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct JavaLib {
    public static func functions() async -> [Modifier] {
        return await [
            typename(),
            defaultValue(),
        ]
    }

    public static func typename() async -> Modifier {
        return await CreateModifier.withoutParams("typename") {
            (value: Sendable, pInfo: ParsedInfo) -> String? in
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
            case .int: return "Integer"
            case .float: return "Float"
            case .double: return "Double"
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

    public static func defaultValue() async -> Modifier {
        return await CreateModifier.withoutParams("default-value") {
            (value: Sendable, pInfo: ParsedInfo) -> String? in

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
            case .int, .double, .float: return "0"
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
