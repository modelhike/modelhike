//
//  Template.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol Template : StringConvertible { 
    var name: String {get}
}

public protocol PlaceHolderTemplate : Template{ }

public protocol ScriptedTemplate :Template { }

public protocol ProgrammedTemplate : Template { }

public enum TemplateStmtKind {
    case block, line, blockOrLine, multiBlock
}

public protocol TemplateItem {
    func execute(with ctx: Context) throws -> String?
}

public protocol TemplateItemWithParsedInfo : TemplateItem {
    var pInfo: ParsedInfo {get}
    func execute(with ctx: Context) throws -> String?
}

public protocol TemplateItemConfig {
    associatedtype T
    
    var keyword : String {get}
    var kind: TemplateStmtKind {get}
    func getNewObject(_ pInfo: ParsedInfo) -> T
}

public protocol TemplateInitialiserWithArg {
    associatedtype T
    
    var initialiser: (String, ParsedInfo) -> T {get}
}

public protocol TemplateInitialiserWithNoArg {
    associatedtype T
    
    var initialiser: (ParsedInfo) -> T {get}
}
