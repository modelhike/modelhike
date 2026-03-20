//
//  Property.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public actor Property : CodeMember {
    public let pInfo: ParsedInfo
    public let attribs = Attributes()
    public let constraints = Constraints()
    public let tags = Tags()
    
    public var name: String
    public var givenname : String
    public var type: TypeInfo
    public var isUnique: Bool = false
    public var isObjectID: Bool = false
    public var isSearchable: Bool = false
    public var required: RequiredKind = .no
    public var arrayMultiplicity: MultiplicityKind = .noBounds
    public private(set) var defaultValue: String?
    public private(set) var validValueSet: String?
    public var comment: String?
    
    public static func parse(pInfo: ParsedInfo) async throws -> Property? {
        let originalLine = pInfo.line
        let firstWord = pInfo.firstWord
        
        let line = originalLine.remainingLine(after: firstWord) //remove first word
        
        guard let match = line.wholeMatch(of: ModelRegEx.property_Capturing)                                                    else { return nil }
        
        let (
            _,
            propName,
            typeName,
            typeMultiplicity,
            validValueSet,
            defaultValue,
            constraintString,
            attributeString,
            tagString
        ) = match.output
        
        let givenName = propName.trim()

        let prop = Property(givenName, pInfo: pInfo)
        
        if let defaultValue = defaultValue {
            await prop.setDefaultValue(defaultValue)
        }

        if let validValueSet = validValueSet {
            await prop.setValidValueSet(validValueSet)
        }

        if let constraintString = constraintString {
            await ParserUtil.populateConstraints(for: prop, from: constraintString)
        }

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
        case ModelConstants.Member_PrimaryKey:
            await prop.required(.yes)
            await prop.primaryKey(true)
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
    
    public func typeKind(from typeName: String) async {
        type.kind = PropertyKind.parse(typeName)
    }
    
    public func typeKind(_ kind: PropertyKind) {
        type.kind = kind
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

    func primaryKey(_ value: Bool) {
        self.isObjectID = value
    }
    
    
    public static func canParse(firstWord: String) -> Bool {
        switch firstWord {
            case ModelConstants.Member_PrimaryKey : return true
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

    public func hasConstraint(_ name: String) async -> Bool {
        return await constraints.has(name)
    }

    public func setDefaultValue(_ value: String?) {
        self.defaultValue = value?.trim()
    }

    public func setValidValueSet(_ value: String?) {
        self.validValueSet = value?.trim()
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


public struct ReferenceTarget: Sendable {
    public var targetName: String
    public var fieldName: String?
    public var targetObject: (any CodeObject)?
    public var fieldProperty: Property?

    public init(
        targetName: String,
        fieldName: String? = nil,
        targetObject: (any CodeObject)? = nil,
        fieldProperty: Property? = nil
    ) {
        self.targetName = targetName
        self.fieldName = fieldName
        self.targetObject = targetObject
        self.fieldProperty = fieldProperty
    }

    public func resolvedFieldTypeName_ForDebugging() async -> String? {
        guard let fieldProperty else {
            return nil
        }
        return await fieldProperty.type.typeNameString_ForDebugging()
    }
}

extension ReferenceTarget: Equatable {
    public static func == (lhs: ReferenceTarget, rhs: ReferenceTarget) -> Bool {
        lhs.targetName == rhs.targetName
            && lhs.fieldName == rhs.fieldName
    }
}

public enum PropertyKind : Equatable, Sendable {
    case unKnown, int, double, float, bool, string, date, datetime, buffer, id, any, 
    reference(ReferenceTarget), multiReference([ReferenceTarget]), extendedReference(ReferenceTarget), 
    multiExtendedReference([ReferenceTarget]), codedValue(String), customType(String)
    
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
            case "reference", "ref":
                let split2 = split1.last!.components(separatedBy: ",")
                if split2.count > 1 { // referenced property, like Reference@Staff,Patient
                    return .multiReference(split2.map(referenceTarget(from:)))
                } else if split1.count == 2 { // referenced property, like Reference@Staff
                    return .reference(referenceTarget(from: split1.last!))
                } else {
                    return .reference(ReferenceTarget(targetName: ""))
                }
            case "extendedreference":
                let split2 = split1.last!.components(separatedBy: ",")
                if split2.count > 1 { // referenced property, like Reference@Staff,Patient
                    return .multiExtendedReference(split2.map(referenceTarget(from:)))
                } else if split1.count == 2 { // referenced property, like Reference@Staff
                    return .extendedReference(referenceTarget(from: split1.last!))
                } else {
                    return .extendedReference(ReferenceTarget(targetName: ""))
                }
            case "codedvalue":
                return .codedValue(split1.last!.normalizeForVariableName())

            default: return .customType(split1.last!.normalizeForVariableName())
        }
    }

    private static func referenceTarget(from value: String) -> ReferenceTarget {
        let components = referenceComponents(from: value)
        return ReferenceTarget(
            targetName: normalizeRawReferenceTarget(components.target),
            fieldName: components.field?.trim().nonEmpty
        )
    }

    private static func referenceComponents(from value: String) -> (target: String, field: String?) {
        let trimmed = value.trim()
        guard trimmed.isEmpty == false else {
            return ("", nil)
        }

        // Quoted targets having spaces in name are the ambiguous case because dots can appear after
        // the closing quote as the field separator, while spaces inside the quotes are part of the
        // target name. Example:
        //   `"Department Lookup".departmentId`
        // Here we treat the final `".` sequence as "end of target, start of field path".
        if trimmed.first == "\"",
           let range = trimmed.range(of: "\".", options: .backwards) {
            let target = String(trimmed[..<range.lowerBound])
            let field = String(trimmed[range.upperBound...])
            return (target, field)
        }

        // For unquoted targets, we intentionally split on the last dot:
        // - `Department.departmentId`      -> target `Department`, field `departmentId`
        // - `Sales.Department.departmentId` -> target `Sales.Department`, field `departmentId`
        //
        // Using the last dot preserves any namespace/schema-style prefix that belongs
        // to the target itself, while still peeling off the referenced field name.
        guard let lastDot = trimmed.lastIndex(of: ".") else {
            return (trimmed, nil)
        }

        let target = String(trimmed[..<lastDot])
        let field = String(trimmed[trimmed.index(after: lastDot)...])

        return (target, field)
    }

    // Normalize only the target side of a parsed `Ref@...` expression, after
    // `referenceComponents(from:)` has already split `target` from `field`.
    //
    // We preserve structure for targets that carry meaning in their original spelling:
    // - `"Department Lookup"` -> `Department Lookup`
    // - `Sales.Department` -> `Sales.Department`
    // - `Department Lookup` -> `Department Lookup`
    //
    // In those cases we only trim whitespace and remove quotes. We do not run
    // `normalizeForVariableName()` because that would collapse spaces or qualification
    // that later model lookup may still need.
    //
    // Only simple targets like `Department` are normalized to the standard internal form.
    private static func normalizeRawReferenceTarget(_ value: String) -> String {
        let target = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if target.contains("\"") || target.contains(".") || target.contains(" ") {
            return target.replacingOccurrences(of: "\"", with: "")
        }
        return target.normalizeForVariableName()
    }

    public var referenceTargets: [ReferenceTarget]? {
        switch self {
        case .reference(let target), .extendedReference(let target):
            return [target]
        case .multiReference(let targets), .multiExtendedReference(let targets):
            return targets
        default:
            return nil
        }
    }

    public var firstReferenceTarget: ReferenceTarget? {
        referenceTargets?.first
    }

    public func replacingReferenceTargets(_ targets: [ReferenceTarget]) -> PropertyKind {
        switch self {
        case .reference:
            return .reference(targets.first ?? ReferenceTarget(targetName: ""))
        case .multiReference:
            return .multiReference(targets)
        case .extendedReference:
            return .extendedReference(targets.first ?? ReferenceTarget(targetName: ""))
        case .multiExtendedReference:
            return .multiExtendedReference(targets)
        default:
            return self
        }
    }
}

public enum MultiplicityKind: Sendable {
    case noBounds, lowerBound(Int), bounded(Int,Int)
}

public enum RequiredKind: Sendable {
    case no, yes, conditional
}
