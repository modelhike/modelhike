//
//  DtoObject.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor DtoObject : CodeObject {
    public var givenname: String
    public var name: String
    public var members : [CodeMember] = []
    public var attachedSections = AttachedSections()
    public var attached : [Artifact] = []
    public var mixins : [CodeObject] = []

    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()
    
    public var derivedProperties : [DerivedProperty] { get async { await members.compactMap({
        if let dprop = $0 as? DerivedProperty { return dprop } else {return nil}
    }) }}
    
    public var properties : [Property] { get async { await members.compactMap({
        if let dprop = $0 as? DerivedProperty { return await dprop.prop } else {return nil}
    }) }}
    
    public var methods : [MethodObject] { members.compactMap({
        if let method = $0 as? MethodObject { return method } else {return nil}
    }) }
    
    public private(set) var dataType: ArtifactKind = .unKnown

    public func dataType(_ value: ArtifactKind) {
        self.dataType = value
    }
    
    public func populateDerivedProperties() async throws {
        var i = 0
        
        while await i < derivedProperties.count {
            let derivedProperty = await derivedProperties[i]
            for mixin in mixins {
                let nameToCompare = await derivedProperty.name.lowercased()
                
                if await mixin.hasProp(nameToCompare) {
                    if let prop = await mixin.getProp(nameToCompare) {
                        await derivedProperty.prop(prop)
                    }
                }

            }
            
            if await derivedProperty.prop == nil { //no matching name found
                let msg = "\(await derivedProperty.givenname) in \(self.givenname)"
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
    
    public var debugDescription: String { get async {
        var str =  """
                    \(self.name) :
                    | Properties \(await self.properties.count) items:
                    """
        str += .newLine
        
        for property in await properties {
            await str += "| " + property.debugDescription + .newLine
            
        }
        
        return str
    }}
    
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
