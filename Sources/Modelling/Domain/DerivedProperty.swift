//
//  DerivedProperty.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class DerivedProperty: CodeMember {
    public let pInfo: ParsedInfo
    public var attribs = Attributes()
    public var tags = Tags()

    public var name: String
    public var givenname: String
    public var type: DerivedPropertyKind = .derived
    public var prop: Property?
    public var obj: DomainObject?

    public var comment: String?

    public static func parse(pInfo: ParsedInfo) throws -> DerivedProperty? {

        let originalLine = pInfo.line
        let firstWord = pInfo.firstWord

        let line = originalLine.remainingLine(after: firstWord)  //remove first word

        guard let match = line.wholeMatch(of: ModelRegEx.derivedProperty_Capturing) else {
            return nil
        }

        let (_, propName, attributeString, tagString) = match.output

        let givenName = propName.trim()

        let prop = DerivedProperty(name: givenName, pInfo: pInfo)

        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: prop, from: attributeString)
        }

        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: prop, from: tagString)
        }

        pInfo.parser.skipLine()

        return prop
    }

    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
        case ModelConstants.Member_Derived_For_Dto: return true
        default: return false
        }
    }

    public func hasAttrib(_ name: String) -> Bool {
        return attribs.has(name)
    }

    public func hasAttrib(_ name: AttributeNamePresets) -> Bool {
        return hasAttrib(name.rawValue)
    }

    public init(name: String, pInfo: ParsedInfo) {
        self.givenname = name.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.pInfo = pInfo
    }

}

public enum DerivedPropertyKind: Equatable {
    case unKnown, derived
}
