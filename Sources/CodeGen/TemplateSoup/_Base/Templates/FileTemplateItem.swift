//
// FileTemplateItem.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol FileTemplateItem {
    func execute(with ctx: Context) throws -> String?
}

public protocol FileTemplateStatement : FileTemplateItem {
}

public protocol FileTemplateStmtConfig : FileTemplateItemConfig {
    
}

public enum TemplateStmtKind {
    case block, line, blockOrLine, multiBlock
}

public protocol FileTemplateItemConfig {
    associatedtype T
    
    var keyword : String {get}
    var kind: TemplateStmtKind {get}
    func getNewObject() -> T
}

public protocol InitialiserWithArg {
    associatedtype T
    
    var initialiser: (String) -> T {get}
}

public protocol InitialiserWithNoArg {
    associatedtype T
    
    var initialiser: () -> T {get}
}
