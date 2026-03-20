//
//  TypeInfo.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct TypeInfo: Sendable {
    public var kind: PropertyKind
    public var isArray: Bool
    
    static func parse(_ str: String) -> TypeInfo {
        if str.hasSuffix("[]") {
            let typeAlone = String(str.dropLast(2))
            let kind = PropertyKind.parse(typeAlone)
            return TypeInfo(kind, isArray: true)
        } else {
            let kind = PropertyKind.parse(str)
            return TypeInfo(kind, isArray: false)
        }
    }
    
    public func isSameAs(_ name: String) -> Bool {
        self.objectString().lowercased() == name.lowercased()
    }
    
    public func isObject() ->  Bool {
        switch self.kind {
            case .reference(_), .multiReference(_), .extendedReference(_), .multiExtendedReference(_):
                return true
            case .codedValue(_):
                return true
            case .customType(_):
                return true
            default:
                return false
        }
    }
    
    public var isNumeric: Bool {
        switch self.kind {
        case .int, .double, .float:
            return true
        default:
            return false
        }
    }
    
    public var isDate: Bool {
        switch self.kind {
        case .date, .datetime:
            return true
        default:
            return false
        }
    }
    
    public var isCustomType : Bool {
        switch self.kind {
            case .customType(_):
                return true
            default:
                return false
        }
    }
    
    public func isCodedValue() ->  Bool {
        switch self.kind {
            case .codedValue(_):
                return true
            default:
                return false
        }
    }
    
    public func isReference() ->  Bool {
        switch self.kind {
            case .reference(_), .multiReference(_):
                return true
            default:
                return false
        }
    }
    
    public func isExtendedReference() ->  Bool {
        switch self.kind {
            case .extendedReference(_), .multiExtendedReference(_):
                return true
            default:
                return false
        }
    }
    
    func objectString() -> String {
        switch self.kind {
            case .reference(let reference):
                return reference.targetName.isEmpty ? "Reference" : "Ref@\(render(reference))"
            case .multiReference(let targets):
                return targets.isEmpty ? "Reference" : "Reference@" + targets.map(render).joined(separator: ",")
            case .extendedReference(let target):
                return target.targetName.isEmpty ? "ExtendedReference" : "ExtendedReference@\(render(target))"
            case .multiExtendedReference(let targets):
                return targets.isEmpty ? "ExtendedReference" : "ExtendedReference@" + targets.map(render).joined(separator: ",")
            case .codedValue(_):
                return "CodedValue"
            case let .customType(typeName):
                return typeName
            default:
                return ""
        }
    }

    public func typeNameString_ForDebugging() -> String {
        switch self.kind {
        case .unKnown:
            return "UnKnown"
        case .int:
            return "Int"
        case .double:
            return "Double"
        case .float:
            return "Float"
        case .bool:
            return "Bool"
        case .string:
            return "String"
        case .date:
            return "Date"
        case .datetime:
            return "DateTime"
        case .buffer:
            return "Buffer"
        case .id:
            return "Id"
        case .any:
            return "Any"
        case .reference(let reference):
            return "Ref@\(render(reference))"
        case .multiReference(let targets):
            return "Reference@" + targets.map(render).joined(separator: ",")
        case .extendedReference(let target):
            return target.targetName.isEmpty ? "ExtendedReference" : "ExtendedReference@\(render(target))"
        case .multiExtendedReference(let targets):
            return "ExtendedReference@" + targets.map(render).joined(separator: ",")
        case .codedValue(let target):
            return "CodedValue@\(target)"
        case .customType(let typeName):
            return typeName
        }
    }
    
    public static func == (lhs: TypeInfo, rhs: PropertyKind) -> Bool {
        return lhs.kind == rhs
    }

    public static func == (lhs: PropertyKind, rhs: TypeInfo) -> Bool {
        return lhs == rhs.kind
    }
    
    public init(_ type: PropertyKind, isArray: Bool) {
        self.kind = type
        self.isArray = isArray
    }
    
    public init(_ type: PropertyKind) {
        self.kind = type
        self.isArray = false
    }
    
    public init(_ type: PropertyKind? = nil) {
        self.kind = type ?? .unKnown
        self.isArray = false
   }
    
    internal init() {
        self.kind = .unKnown
        self.isArray = false
    }

    private func render(_ target: ReferenceTarget) -> String {
        var rendered = target.targetName
        if let fieldName = target.fieldName, fieldName.isNotEmpty {
            rendered += ".\(fieldName)"
        }
        return rendered
    }
}
