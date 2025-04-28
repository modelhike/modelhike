//
//  ContentLine.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct ContentLine: TemplateItem, CustomDebugStringConvertible {
    public var items: [ContentLineItem] = []
    public let level: Int
    public let pInfo: ParsedInfo

    fileprivate mutating func parseLine(_ line: String) async throws {
        self.items = try await ContentHandler.parseLine(line, pInfo: pInfo, level: level)
    }

    public func execute(with ctx: Context) async throws -> String? {
        var str = ""

        for item in items {
            if let result = try await item.execute(with: ctx) {
                str += result
            }
        }

        return str.trim().isNotEmpty ? str + .newLine : nil
    }

    public var debugDescription: String {
        var str = ""

        for item in items {
            str += item.debugDescription + .newLine
        }

        return str
    }

    public init(_ pInfo: ParsedInfo, level: Int) async throws {
        self.pInfo = pInfo
        self.level = level

        try await self.parseLine(pInfo.line)
    }
}

public protocol ContentLineItem : Sendable, CustomDebugStringConvertible{
    var pInfo: ParsedInfo {get}
    func execute(with ctx: Context) async throws -> String?
}
