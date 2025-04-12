//
//  Template.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Template: StringConvertible, Sendable {
    var name: String {get}
}

public protocol PlaceHolderTemplate: Template { }

public protocol ScriptedTemplate: Template { }

public protocol ProgrammedTemplate: Template { }

public enum TemplateStmtKind: Sendable {
    case block, line, blockOrLine, multiBlock
}

public protocol TemplateItem: Sendable {
    func execute(with ctx: Context) throws -> String?
}

public protocol TemplateItemWithParsedInfo: TemplateItem {
    var pInfo: ParsedInfo {get}
    func execute(with ctx: Context) throws -> String?
}

public protocol TemplateItemConfig: Sendable {
    associatedtype T
    
    var keyword : String {get}
    var kind: TemplateStmtKind {get}
    func getNewObject(_ pInfo: ParsedInfo) -> T
}

public protocol TemplateInitialiserWithArg: Sendable {
    associatedtype T
    
    var initialiser: @Sendable (String, ParsedInfo) -> T {get}
}

public protocol TemplateInitialiserWithNoArg: Sendable {
    associatedtype T
    
    var initialiser: @Sendable (ParsedInfo) -> T {get}
}
