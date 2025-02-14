//
// CreateModifier.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct CreateModifier {
    public static func withoutParams<I, T>(_ name: String, body: @escaping (I, ParsedInfo) throws -> T?) -> Modifier {
        
        return ModifierWithoutArgs(name: name , handler: body)
    }

    public static func withParams<I, T>(_ name: String, body: @escaping (I, [Any], ParsedInfo) throws -> T?) -> Modifier {
        
        return ModifierWithUnNamedArgs(name: name, handler: body)
    }

}
