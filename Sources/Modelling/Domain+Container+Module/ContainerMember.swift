//
// ContainerMember.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ContainerModuleMember : Artifact {
    public var attribs = Attributes()
    public var tags = Tags()
    public var annotations = Annotations()

    public var name: String
    public var type: ContainerKind = .unKnown
    public var comment: String?
    
    public func hasAttrib(_ name: String) -> Bool {
        return attribs.has(name)
    }
    
    public func hasAttrib(_ name: AttributeNamePresets) -> Bool {
        return hasAttrib(name.rawValue)
    }
    
    static func parse(_ originalLine: String, firstWord: String) throws -> ContainerModuleMember? {
        
        var module = ContainerModuleMember()

        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.container_Member_Capturing)                                                    else { return nil }
        
        let (_, moduleName, attributeString, tagString) = match.output

        module.name = moduleName.trim()
        
        //check if has attributes
        if let attributeString = attributeString {
            let attribMatches = attributeString.matches(of: ModelRegEx.attributes_Capturing)
            
            let _ = attribMatches.map( { match in
                let (_, name, value) = match.output
                
                if let name = name, let value = value { // key-value attribute
                    module.attribs[name.trim()] = value as Any
                } else if let name = name {
                    //add the key as value
                    module.attribs[name.trim()] = name.trim()
                }
            })
        }
        
        //check if has tags
        if let tagString = tagString {
            let tagMatches = tagString.matches(of: ModelRegEx.tags_Capturing)
            
            let _ = tagMatches.map( { match in
                let (_, tag) = match.output
                module.tags.append(String(tag))
            })
        }
        
        return module
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Container_Module_Member : return true
            default :
                return false
        }
    }
    
    public init(_ name: String) {
        self.name = name.normalizeForVariableName()
    }
    
    public init() {
        self.name = "unKnown"
    }
    
    public init(_ name: String, type: ContainerKind) {
        self.name = name.normalizeForVariableName()
        self.type = type
    }
}


public enum ContainerKind : Equatable {
    case unKnown, microservices, microservice
}
