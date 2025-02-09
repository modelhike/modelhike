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

    public var name: String = ""
    public var givenname: String = ""
    public let dataType: ArtifactKind = .container

    public var comment: String?
    
    public func hasAttrib(_ name: String) -> Bool {
        return attribs.has(name)
    }
    
    public func hasAttrib(_ name: AttributeNamePresets) -> Bool {
        return hasAttrib(name.rawValue)
    }
    
    static func parse(with pctx: ParsedInfo) throws -> ContainerModuleMember? {
        let originalLine = pctx.line
        let firstWord = pctx.firstWord
        
        var module = ContainerModuleMember()

        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.container_Member_Capturing)                                                                                else { return nil }
        
        let (_, moduleName, attributeString, tagString) = match.output

        module.name = moduleName.trim()
        
        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: module, from: attributeString)
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: module, from: tagString)
        }
        
        pctx.parser.skipLine()

        return module
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Container_Member : return true
          default :
                return false
        }
    }
    
    public init(_ name: String) {
        self.name = name.normalizeForVariableName()
        self.givenname = name
    }
    
    public init() {
        self.name = "unKnown"
        self.givenname = name
    }
    
}
