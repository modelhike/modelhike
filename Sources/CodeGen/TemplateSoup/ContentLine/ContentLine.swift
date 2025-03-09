//
//  ContentLine.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public class ContentLine: TemplateItem, CustomDebugStringConvertible {
    public var items: [ContentLineItem] = []
    public let level: Int
    public let pInfo: ParsedInfo

    fileprivate func parseLine(_ line: String) throws {
        self.items = try ContentHandler.parseLine(line, pInfo: pInfo, level: level)
    }

    public func execute(with ctx: Context) throws -> String? {
        var str = ""

        for item in items {
            if let result = try item.execute(with: ctx) {
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

    public init(_ pInfo: ParsedInfo, level: Int) throws {
        self.pInfo = pInfo
        self.level = level

        try self.parseLine(pInfo.line)
    }
}

public protocol ContentLineItem : CustomDebugStringConvertible{
    var pInfo: ParsedInfo {get}
    func execute(with ctx: Context) throws -> String?
}
