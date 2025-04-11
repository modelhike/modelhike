//
//  Property.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor Property : CodeMember {
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
    
    public static func parse(pInfo: ParsedInfo) async throws -> Property? {
        let originalLine = pInfo.line
        let firstWord = pInfo.firstWord
        
        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.property_Capturing)                                                    else { return nil }
        
        let (_, propName, typeName, typeMultiplicity, attributeString, _, tagString) = match.output
        
        let givenName = propName.trim()

        let prop = Property(givenName, pInfo: pInfo)
        
        //check if has attributes
        if let attributeString = attributeString {
            await ParserUtil.populateAttributes(for: prop, from: attributeString)
        }
        
        await prop.typeKind(from: typeName)
        
        //check if has multiplicity
        if let multiplicity = typeMultiplicity {
            await prop.isArray(true)

            if multiplicity.trim() == "*" {
              await  prop.arrayMultiplicity(.noBounds)
            } else {
                let boundSplit = multiplicity.components(separatedBy: "..")
                if boundSplit.count == 2 && boundSplit.last! != "*" {
                    let value: MultiplicityKind = .bounded(Int(boundSplit.first!)!, Int(boundSplit.last!)!)
                    await prop.arrayMultiplicity(value)
                } else {
                    let value: MultiplicityKind = .lowerBound(Int(boundSplit.first!)!)
                    await prop.arrayMultiplicity(value)
                }
            }
        }
        
        //check if has tags
        if let tagString = tagString {
            await ParserUtil.populateTags(for: prop, from: tagString)
        }
        
        switch firstWord {
        case ModelConstants.Member_Mandatory : await prop.required(.yes)
            case ModelConstants.Member_Optional, ModelConstants.Member_Optional2 :
            await prop.required(.no)
           default :
            if firstWord.starts(with: ModelConstants.Member_Conditional) {
                await prop.required(.conditional)
            } else {
                await prop.required(.no)
            }
        }
        
        await pInfo.parser.skipLine()

        return prop
    }
    
    public func typeKind(from typeName: String) {
        type.kind = PropertyKind.parse(typeName)
    }
    
    func isArray(_ value: Bool) {
        type.isArray = value
    }
    
    func arrayMultiplicity(_ kind: MultiplicityKind) {
        self.arrayMultiplicity = kind
    }
    
    func required(_ value: RequiredKind) {
        self.required = value
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
    
    public func hasAttrib(_ name: String) async -> Bool {
        return await attribs.has(name)
    }
    
    public func hasAttrib(_ name: AttributeNamePresets) async -> Bool {
        return await hasAttrib(name.rawValue)
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


public enum PropertyKind : Equatable, Sendable {
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

public enum MultiplicityKind: Sendable {
    case noBounds, lowerBound(Int), bounded(Int,Int)
}

public enum RequiredKind: Sendable {
    case no, yes, conditional
}
