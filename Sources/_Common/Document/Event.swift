//
// Event.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct Event: Hashable {
    public let name: String
    public let scriptToExecute: String?
    
    public init(_ name: String, script: String?) {
        self.name = name
        self.scriptToExecute = script
    }
}

public struct EventSet : ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = String?
    private var items: Set<Event> = Set()
    
    public init(dictionaryLiteral elements: (String, String?)...) {
        for (name,script) in elements {
            items.insert(Event(name, script: script))
        }
    }
}
