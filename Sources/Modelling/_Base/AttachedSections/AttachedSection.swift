//
// AttachedSection.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class AttachedSection : ArtifactContainer {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String = ""
    public var givename: String = ""
    public let dataType: ArtifactKind = .attachedSection

    public internal(set) var items : [Artifact]
    public internal(set) var lines : [String]

    public func append(_ line: String) {
        self.lines.append(line)
    }
    
    public init(code: String) {
        self.name = code
        self.givename = code
        self.items = []
        self.lines = []
    }
}
