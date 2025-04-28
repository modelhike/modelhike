//
//  CreateModifier.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct CreateModifier {
    public static func withoutParams<I, T: Sendable>(_ name: String, body: @Sendable @escaping (I, ParsedInfo) async throws -> T?) async -> Modifier {
        
        return  ModifierWithoutArgs(name: name , handler: body)
    }

    public static func withParams<I, T: Sendable>(_ name: String, body: @Sendable @escaping (I, [Sendable], ParsedInfo)  async throws -> T?) async -> Modifier {
        
        return  ModifierWithUnNamedArgs(name: name, handler: body)
    }

}
