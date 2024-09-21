//
// Property.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct Property : CodeMember {
    public var attribs = Attributes()
    public var tags = Tags()
    
    public var name: String
    public var givename : String
    public var type: PropertyKind = .unKnown
    public var isUnique: Bool = false
    public var isObjectID: Bool = false
    public var isSearchable: Bool = false
    public var required: RequiredKind = .no
    public var isArray: Bool = false
    public var arrayMultiplicity: MultiplicityKind = .noBounds
    public var comment: String?
    
    public func hasAttrib(_ name: String) -> Bool {
        return attribs.has(name)
    }
    
    public func hasAttrib(_ name: AttributeNamePresets) -> Bool {
        return hasAttrib(name.rawValue)
    }
    
    static func parse(_ originalLine: String, firstWord: String) throws -> Property? {
        
        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.property_Capturing)                                                    else { return nil }
        
        let (_, propName, typeName, typeMultiplicity, attributeString, _, tagString) = match.output
        
        let givenName = propName.trim()

        var prop = Property(givenName)
        
        //check if has attributes
        if let attributeString = attributeString {
            let attribMatches = attributeString.matches(of: ModelRegEx.attributes_Capturing)
            
            let _ = attribMatches.map( { match in
                let (_, name, value) = match.output
                
                if let name = name, let value = value { // key-value attribute
                    prop.attribs[name.trim()] = value as Any
                } else if let name = name {
                    //add the key as value
                    prop.attribs[name.trim()] = name.trim()
                }
            })
        }
        
        prop.type = PropertyKind.parse(typeName)
        
        //check if has multiplicity
        if let multiplicity = typeMultiplicity {
            prop.isArray = true

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
            let tagMatches = tagString.matches(of: ModelRegEx.tags_Capturing)
            
            let _ = tagMatches.map( { match in
                let (_, tag) = match.output
                prop.tags.append(String(tag))
            })
        }
        
        switch firstWord {
            case ModelConstants.Attribute_Mandatory : prop.required = .yes
            case ModelConstants.Attribute_Optional : prop.required = .no
            default :
            if firstWord.starts(with: ModelConstants.Attribute_Conditional) {
                prop.required = .conditional
            } else {
                prop.required = .no
            }
        }
        
        return prop
    }
    
    public func isObject() ->  Bool {
        switch self.type {
            case .reference(_), .multiReference(_), .extendedReference(_), .multiExtendedReference(_):
                return true
            case .codedValue(_):
                return true
            case .customType(_):
                return true
            default:
                return false
        }
    }
    
    public func isCustomType() ->  Bool {
        switch self.type {
            case .customType(_):
                return true
            default:
                return false
        }
    }
    
    public func isCodedValue() ->  Bool {
        switch self.type {
            case .codedValue(_):
                return true
            default:
                return false
        }
    }
    
    public func isReference() ->  Bool {
        switch self.type {
            case .reference(_), .multiReference(_):
                return true
            default:
                return false
        }
    }
    
    public func isExtendedReference() ->  Bool {
        switch self.type {
            case .extendedReference(_), .multiExtendedReference(_):
                return true
            default:
                return false
        }
    }
    
    func getObjectString() -> String {
        switch self.type {
            case .reference(_):
                return "Reference"
            case .multiReference(_):
                return "Reference"
            case .extendedReference(_):
                return "ExtendedReference"
            case .multiExtendedReference(_):
                return "ExtendedReference"
            case .codedValue(_):
                return "CodedValue"
            case let .customType(typeName):
                return typeName
            default:
                return ""
        }
    }
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Attribute_Mandatory : return true
            case ModelConstants.Attribute_Optional : return true
            default :
            if firstWord.starts(with: ModelConstants.Attribute_Conditional) {
                return true
            } else {
                return false
            }
        }
    }
    
    public init(_ givenName: String) {
        self.givename = givenName
        self.name = givenName.normalizeForVariableName()
    }
    
    public init(_ givenName: String, type: PropertyKind, isUnique: Bool = false, required: RequiredKind = .no) {
        self.givename = givenName
        self.name = givenName.normalizeForVariableName()
        self.type = type
        self.isUnique = isUnique
        self.required = required
    }
    
    public init(_ givenName: String, type: PropertyKind, isObjectID: Bool, required: RequiredKind = .no) {
        self.givename = givenName
        self.name = givenName.normalizeForVariableName()
        self.type = type
        self.isObjectID = isObjectID
        self.required = required
    }
    
    public init(_ givenName: String, type: PropertyKind, isArray: Bool, arrayMultiplicity: MultiplicityKind, required: RequiredKind = .no) {
        self.givename = givenName
        self.name = givenName.normalizeForVariableName()
        self.type = type
        self.required = required
        self.isArray = isArray
        self.arrayMultiplicity = arrayMultiplicity
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
