//
//  CheckSendable.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//
import Foundation

public func CheckSendable(_ propname: String, value: Any, pInfo: ParsedInfo) throws -> Sendable? {
    switch value {
    case let v as Int:
        return v
    case let v as String:
        return v
    case let v as Bool:
        return v
    case let v as Double:
        return v
    case let v as Float:
        return v
    case let v as Character:
        return v
    case let v as Date:
        return v
    case let v as Decimal:
        return v
    case let v as UUID:
        return v
    case let v as URL:
        return v
    case let v as Data:
        return v
    default:
        throw TemplateSoup_EvaluationError.nonSendablePropertyValue(propname, pInfo)
    }
}

public func CheckSendable(value: Any, pInfo: ParsedInfo) throws -> Sendable? {
    switch value {
    case let v as Int:
        return v
    case let v as String:
        return v
    case let v as Bool:
        return v
    case let v as Double:
        return v
    case let v as Float:
        return v
    case let v as Character:
        return v
    case let v as Date:
        return v
    case let v as Decimal:
        return v
    case let v as UUID:
        return v
    case let v as URL:
        return v
    case let v as Data:
        return v
    default:
        let errDisplay = "\(String(describing: type(of: value))) \(value)"
        throw TemplateSoup_EvaluationError.nonSendableValueFound(errDisplay, pInfo)
    }
}
