//
//  TypeInfo.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct TypeInfo: Sendable {
    public let kind: PropertyKind
    public let isArray: Bool
    
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
    
    public var isCustomType :  Bool {
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
            default:
                return ""
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
}
