//
// CodeMember.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol CodeMember : HasAttributes, HasTags, CustomDebugStringConvertible {
    var name: String {get}
    var givenname : String {get}
}

public extension CodeMember {
    var debugDescription: String {
        return String(describing: self)
    }
}

typealias CodeMemberBuilder = ResultBuilder<CodeMember>
