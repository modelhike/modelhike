//
// CodeMember.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol CodeMember : HasAttributes, HasTags {
    
}

typealias CodeMemberBuilder = ResultBuilder<CodeMember> 
