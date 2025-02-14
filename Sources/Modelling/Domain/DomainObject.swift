//
// DomainObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class DomainObject : CodeObject {
    public var givenname: String
    public var name: String
    public var members : [CodeMember] = []
    public var attachedSections = AttachedSections()
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []

    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public lazy var properties : [Property] = { members.compactMap({
        if let prop = $0 as? Property { return prop } else {return nil}
    }) }()
    
    public lazy var methods : [MethodObject] = { members.compactMap({
        if let method = $0 as? MethodObject { return method } else {return nil}
    }) }()
    
    public var dataType: ArtifactKind = .unKnown

    @discardableResult
    func append(_ item: CodeMember) -> Self {
        members.append(item)
        return self
    }
    
    public var debugDescription: String {
        var str =  """
                    \(self.name) :
                    | Properties \(self.properties.count) items:
                    """
        str += .newLine

        for property in properties {
            str += "| " + property.debugDescription + .newLine
            
        }
        
        return str
    }
    
    public init(name: String, @CodeMemberBuilder _ builder: () -> [CodeMember]) {
        self.givenname = name.trim()
        self.name = name.normalizeForVariableName()
        self.members = builder()
    }
    
    public init(name: String) {
        self.givenname = name.trim()
        self.name = name.normalizeForVariableName()
    }
    
}
