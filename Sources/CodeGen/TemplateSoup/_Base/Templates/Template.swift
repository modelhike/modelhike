//
// Template.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
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

public protocol TemplateItemConfig {
    associatedtype T
    
    var keyword : String {get}
    var kind: TemplateStmtKind {get}
    func getNewObject() -> T
}

public protocol TemplateInitialiserWithArg {
    associatedtype T
    
    var initialiser: (String) -> T {get}
}

public protocol TemplateInitialiserWithNoArg {
    associatedtype T
    
    var initialiser: () -> T {get}
}
