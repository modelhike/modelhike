//
// DomainObject.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class DomainObject : CodeObject {
    public var givename: String
    public var name: String
    public var members : [CodeMember] = []
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []

    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public lazy var properties : [Property] = { members.compactMap({
        if let prop = $0 as? Property { return prop } else {return nil}
    }) }()
    
    public lazy var methods : [Method] = { members.compactMap({
        if let method = $0 as? Method { return method } else {return nil}
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
                    Properties \(self.properties.count) items:
                    """
        str += .newLine

        for property in properties {
            str += property.debugDescription + .newLine
            
        }
        
        return str
    }
    
    public init(name: String, @CodeMemberBuilder _ builder: () -> [CodeMember]) {
        self.givename = name.trim()
        self.name = name.normalizeForVariableName()
        self.members = builder()
    }
    
    public init(name: String) {
        self.givename = name.trim()
        self.name = name.normalizeForVariableName()
    }
    
}
