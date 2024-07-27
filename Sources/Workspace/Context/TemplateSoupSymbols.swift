//
// TemplateSoupSymbols.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct TemplateSoupSymbols {
    public private(set) var modifiers: [String: Modifier] = [:]
    public private(set) var statements: [any FileTemplateStmtConfig] = []
    public private(set) var infixOperators: [InfixOperatorProtocol] = []

    public mutating func add(modifiers modifiersList: [Modifier]) {
        for modifier in modifiersList {
            self.modifiers[modifier.name] = modifier
        }
    }
    
    public mutating func add(stmts stmtsList: [any FileTemplateStmtConfig]) {
        self.statements.append(contentsOf: stmtsList)
    }
    
    public mutating func add(infixOperators operatorsList: [InfixOperatorProtocol]) {
        self.infixOperators.append(contentsOf: operatorsList)
    }
}
