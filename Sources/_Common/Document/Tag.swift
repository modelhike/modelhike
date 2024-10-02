//
// Tag.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public protocol HasTags {
    var tags: Tags {get set}
}

public class Tags {
    public var items: [String] = []
    
    @discardableResult
    func append(_ str: String) -> Self {
        items.append(str)
        return self
    }
}
