//
//  Property.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public class Property : CodeMember {
    public let pInfo: ParsedInfo
    public var attribs = Attributes()
    public var tags = Tags()
    
    public var name: String
    public var givenname : String
    public var type: TypeInfo
    public var isUnique: Bool = false
    public var isObjectID: Bool = false
    public var isSearchable: Bool = false
    public var required: RequiredKind = .no
    public var arrayMultiplicity: MultiplicityKind = .noBounds
    public var comment: String?
    
    public static func parse(pInfo: ParsedInfo) throws -> Property? {
        let originalLine = pInfo.line
        let firstWord = pInfo.firstWord
        
        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.property_Capturing)                                                    else { return nil }
        
        let (_, propName, typeName, typeMultiplicity, attributeString, _, tagString) = match.output
        
        let givenName = propName.trim()

        let prop = Property(givenName, pInfo: pInfo)
        
        //check if has attributes
        if let attributeString = attributeString {
            ParserUtil.populateAttributes(for: prop, from: attributeString)
        }
        
        prop.type.kind = PropertyKind.parse(typeName)
        
        //check if has multiplicity
        if let multiplicity = typeMultiplicity {
            prop.type.isArray = true

            if multiplicity.trim() == "*" {
                prop.arrayMultiplicity = .noBounds
            } else {
                let boundSplit = multiplicity.components(separatedBy: "..")
                if boundSplit.count == 2 && boundSplit.last! != "*" {
                    prop.arrayMultiplicity = .bounded(Int(boundSplit.first!)!, Int(boundSplit.last!)!)
                } else {
                    prop.arrayMultiplicity = .lowerBound(Int(boundSplit.first!)!)
                }
            }
        }
        
        //check if has tags
        if let tagString = tagString {
            ParserUtil.populateTags(for: prop, from: tagString)
        }
        
        switch firstWord {
            case ModelConstants.Member_Mandatory : prop.required = .yes
            case ModelConstants.Member_Optional, ModelConstants.Member_Optional2 : prop.required = .no
           default :
            if firstWord.starts(with: ModelConstants.Member_Conditional) {
                prop.required = .conditional
            } else {
                prop.required = .no
            }
        }
        
        pInfo.parser.skipLine()

        return prop
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Member_Mandatory : return true
            case ModelConstants.Member_Optional, ModelConstants.Member_Optional2 : return true
            default :
                if firstWord.starts(with: ModelConstants.Member_Conditional) {
                    return true
                } else {
                    return false
                }
        }
    }
    
    public func hasAttrib(_ name: String) -> Bool {
        return attribs.has(name)
    }
    
    public func hasAttrib(_ name: AttributeNamePresets) -> Bool {
        return hasAttrib(name.rawValue)
    }
    
    public init(_ givenName: String, pInfo: ParsedInfo) {
        self.givenname = givenName.trim()
        self.type = TypeInfo()
        self.name = self.givenname.normalizeForVariableName()
        self.pInfo = pInfo
    }
    
    public init(_ givenName: String, type: PropertyKind, isUnique: Bool = false, required: RequiredKind = .no, pInfo: ParsedInfo) {
        self.givenname = givenName.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.type = TypeInfo(type)
        self.isUnique = isUnique
        self.required = required
        self.pInfo = pInfo
    }
    
    public init(_ givenName: String, type: PropertyKind, isObjectID: Bool, required: RequiredKind = .no, pInfo: ParsedInfo) {
        self.givenname = givenName.trim()
        self.name = self.givenname.normalizeForVariableName()
        self.type = TypeInfo(type)
        self.isObjectID = isObjectID
        self.required = required
        self.pInfo = pInfo
    }
    
    public init(_ givenName: String, type: PropertyKind, isArray: Bool, arrayMultiplicity: MultiplicityKind, required: RequiredKind = .no, pInfo: ParsedInfo) {
        self.givenname = givenName.trim()
        self.name = self.givenname.normalizeForVariableName()
        
        let typeInfo = TypeInfo(type, isArray: isArray)
        self.type = typeInfo
        self.required = required
        self.arrayMultiplicity = arrayMultiplicity
        self.pInfo = pInfo
    }
}


public enum PropertyKind : Equatable {
    case unKnown, int, double, float, bool, string, date, datetime, buffer, id, any, reference(String), multiReference([String]), extendedReference(String), multiExtendedReference([String]), codedValue(String), customType(String)
    
    static func parse(_ str: String) -> PropertyKind {
        let split1 = str.trim().components(separatedBy: "@")
        
        switch split1.first!.lowercased() {
            case "int", "integer" : return .int
            case "number", "decimal", "double", "float" : return .double
            case "bool", "boolean", "yesno", "yes/no" : return .bool
            case "string", "text": return .string
            case "date" : return .date
            case "datetime" : return .datetime
            case "buffer": return .buffer
            case "id": return .id
            case "any": return .any
            case "reference":
                var split2 = split1.last!.components(separatedBy: ",")
                if split2.count > 1 { // referenced property, like Reference@Staff,Patient
                    split2 = split2.map({$0.normalizeForVariableName()})
                    return .multiReference(split2)
                } else if split1.count == 2 { // referenced property, like Reference@Staff
                    return .reference(split1.last!.normalizeForVariableName())
                } else {
                    return .reference("")
                }
            case "extendedreference":
                var split2 = split1.last!.components(separatedBy: ",")
                if split2.count > 1 { // referenced property, like Reference@Staff,Patient
                    split2 = split2.map({$0.normalizeForVariableName()})
                    return .multiExtendedReference(split2)
                } else if split1.count == 2 { // referenced property, like Reference@Staff
                    return .extendedReference(split1.last!.normalizeForVariableName())
                } else {
                    return .extendedReference("")
                }
            case "codedvalue":
                return .codedValue(split1.last!.normalizeForVariableName())

            default: return .customType(split1.last!.normalizeForVariableName())
        }
    }
}

public enum MultiplicityKind {
    case noBounds, lowerBound(Int), bounded(Int,Int)
}

public enum RequiredKind {
    case no, yes, conditional
}
