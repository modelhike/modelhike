//
//  DtoObject.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class DtoObject : CodeObject {
    public var givenname: String
    public var name: String
    public var members : [CodeMember] = []
    public var attachedSections = AttachedSections()
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []

    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public lazy var derivedProperties : [DerivedProperty] = { members.compactMap({
        if let dprop = $0 as? DerivedProperty { return dprop } else {return nil}
    }) }()
    
    public lazy var properties : [Property] = { members.compactMap({
        if let dprop = $0 as? DerivedProperty { return dprop.prop } else {return nil}
    }) }()
    
    public lazy var methods : [MethodObject] = { members.compactMap({
        if let method = $0 as? MethodObject { return method } else {return nil}
    }) }()
    
    public var dataType: ArtifactKind = .unKnown
    
    public func populateDerivedProperties() throws {
        var i = 0
        
        while i < derivedProperties.count {
            let derivedProperty = derivedProperties[i]
            for mixin in mixins {
                let nameToCompare = derivedProperty.name.lowercased()
                
                if mixin.hasProp(nameToCompare) {
                    if let prop = mixin.getProp(nameToCompare) {
                        derivedProperty.prop = prop
                    }
                }

            }
            
            if derivedProperty.prop == nil { //no matching name found
                let msg = "\(derivedProperty.givenname) in \(self.givenname)"
                throw Model_ParsingError.invalidDerivedProperty(msg, derivedProperty.pInfo)
            }
            
            i += 1
        }
    }
    
    @discardableResult
    public func append(_ item: CodeMember) -> Self {
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
