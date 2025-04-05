//
//  CodeMember.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public protocol CodeMember: HasAttributes_Actor, HasTags_Actor, CustomDebugStringConvertible, Actor {
    var pInfo: ParsedInfo { get }
    var name: String { get }
    var givenname: String { get }
}

extension CodeMember {
    public var debugDescription: String {
        return givenname
    }
}

typealias CodeMemberBuilder = ResultBuilder<CodeMember>
