//
//  DefaultModifiersLibrary.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct DefaultModifiersLibrary {

    public static var modifiers: [Modifier] {
        return [
            length,
            capitalise,
            lowercase,
            uppercase,
            lowercaseFirst,
            uppercaseFirst,
            trim,
            
            replacewith,
            
            urlEncode,
            urlDecode,
            nl2br,

            absoluteValue,

            minFunction,
            maxFunction,
            sumFunction,
            sqrtFunction,
            roundFunction,
            averageFunction,

            arrayCountFunction,
            arraySortFunction,
            arrayReverseFunction,
            arrayMinFunction,
            arrayMaxFunction,
            arrayFirstFunction,
            arrayLastFunction,
            arrayJoinFunction,
            arraySumFunction,
            arrayAverageFunction,

            dictionaryCountFunction,
            dictionaryKeys,
            dictionaryValues,

            dateFactory,
            dateFormat
        ]
    }


    static var length: Modifier {
        return CreateModifier.withoutParams("length") { (value: String, pInfo: ParsedInfo) -> Double? in Double(value.count) }
    }
    
    public static var capitalise: Modifier {
        return CreateModifier.withoutParams("capitalise") { (value: String, pInfo: ParsedInfo) -> String? in value.capitalized }
    }

    public static var lowercase: Modifier {
        return CreateModifier.withoutParams("lowercase") { (value: String, pInfo: ParsedInfo) -> String? in value.lowercased() }
    }

    public static var uppercase: Modifier {
        return CreateModifier.withoutParams("uppercase") { (value: String, pInfo: ParsedInfo) -> String? in value.uppercased() }
    }

    public static var lowercaseFirst: Modifier {
        return CreateModifier.withoutParams("lowerFirst") { (value: String, pInfo: ParsedInfo) -> String? in
            guard let first = value.first else { return nil }
            return String(first).lowercased() + value[value.index(value.startIndex, offsetBy: 1)...]
        }
    }

    public static var uppercaseFirst: Modifier {
        return CreateModifier.withoutParams("upperFirst") { (value: String, pInfo: ParsedInfo) -> String? in
            guard let _ = value.first else { return nil }
            return value.uppercasedFirst()
        }
    }

    public static var trim: Modifier {
        return CreateModifier.withoutParams("trim") { (value: String, pInfo: ParsedInfo) -> String? in value.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public static var replacewith: Modifier {
        return CreateModifier.withParams("replace") { (value: String, arguments: [Any], pInfo: ParsedInfo) throws -> String? in
            if arguments.count != 2 { throw TemplateSoup_ParsingError.modifierInvalidArguments("replace", pInfo) }
            
            guard let replaceFrom = arguments.first as? String,
                  let replaceWith = arguments[1] as? String else { return nil }
            return value.replacingOccurrences(of: replaceFrom, with: replaceWith)
        }
    }
    
    public static var urlEncode: Modifier {
        return CreateModifier.withoutParams("urlEncode") { (value: String, pInfo: ParsedInfo) -> String? in value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) }
    }

    public static var urlDecode: Modifier {
        return CreateModifier.withoutParams("urlDecode") { (value: String, pInfo: ParsedInfo) -> String? in value.removingPercentEncoding }
    }

    public static var nl2br: Modifier {
        return CreateModifier.withoutParams("nl2br") { (value: String, pInfo: ParsedInfo) -> String? in value
            .replacingOccurrences(of: "\r\n", with: "<br/>")
            .replacingOccurrences(of: "\n", with: "<br/>")
        }
    }

    public static var absoluteValue: Modifier {
        return CreateModifier.withoutParams("abs") { (value: Double, pInfo: ParsedInfo) -> Double? in abs(value) }
    }

    public static var minFunction: Modifier {
        return CreateModifier.withoutParams("min") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.min()
        }
    }

    public static var maxFunction: Modifier {
        return CreateModifier.withoutParams("max") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.max()
        }
    }

    public static var arraySortFunction: Modifier {
        return CreateModifier.withoutParams("sort") { (object: [Double], pInfo: ParsedInfo) -> [Double]? in object.sorted() }
    }

    public static var arrayReverseFunction: Modifier {
        return CreateModifier.withoutParams("reverse") { (object: [Double], pInfo: ParsedInfo) -> [Double]? in object.reversed() }
    }

    public static var arrayMinFunction: Modifier {
        return CreateModifier.withoutParams("min") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.min() }
    }

    public static var arrayMaxFunction: Modifier {
        return CreateModifier.withoutParams("max") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.max() }
    }

    public static var arrayFirstFunction: Modifier {
        return CreateModifier.withoutParams("first") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.first }
    }

    public static var arrayLastFunction: Modifier {
        return CreateModifier.withoutParams("last") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.last }
    }

    public static var arrayJoinFunction: Modifier {
        return CreateModifier.withParams("join") { (object: [String], arguments: [Any], pInfo: ParsedInfo) -> String? in
            guard let separator = arguments.first as? String else { return nil }
            return object.joined(separator: separator)
        }
    }

    public static var arraySumFunction: Modifier {
        return CreateModifier.withoutParams("sum") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.reduce(0, +) }
    }

    public static var arrayAverageFunction: Modifier {
        return CreateModifier.withoutParams("avg") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.reduce(0, +) / Double(object.count) }
    }

    public static var arrayCountFunction: Modifier {
        return CreateModifier.withoutParams("count") { (object: [Double], pInfo: ParsedInfo) -> Double? in Double(object.count) }
    }

    public static var dictionaryCountFunction: Modifier {
        return CreateModifier.withoutParams("count") { (object: [String: Any], pInfo: ParsedInfo) -> Double? in Double(object.count) }
    }

    public static var sumFunction: Modifier {
        return CreateModifier.withoutParams("sum") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.reduce(0, +)
        }
    }

    public static var averageFunction: Modifier {
        return CreateModifier.withoutParams("avg") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.reduce(0, +) / Double(arguments.count)
        }
    }

    public static var sqrtFunction: Modifier {
        return CreateModifier.withoutParams("sqrt") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let value = arguments.first as? Double else { return nil }
            return sqrt(value)
        }
    }

    public static var roundFunction: Modifier {
        return CreateModifier.withoutParams("round") { (arguments: [Any], pInfo: ParsedInfo) -> Double? in
            guard let value = arguments.first as? Double else { return nil }
            return round(value)
        }
    }

    public static var dateFactory: Modifier {
        return CreateModifier.withoutParams("Date") { (arguments: [Any], pInfo: ParsedInfo) -> Date? in
            guard let arguments = arguments as? [Double], arguments.count >= 3 else { return nil }
            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.year = Int(arguments[0])
            components.month = Int(arguments[1])
            components.day = Int(arguments[2])
            components.hour = arguments.count > 3 ? Int(arguments[3]) : 0
            components.minute = arguments.count > 4 ? Int(arguments[4]) : 0
            components.second = arguments.count > 5 ? Int(arguments[5]) : 0
            return components.date
        }
    }

    public static var dateFormat: Modifier {
        return CreateModifier.withParams("format") { (object: Date, arguments: [Any], pInfo: ParsedInfo) -> String? in
            guard let format = arguments.first as? String else { return nil }
            let dateFormatter = DateFormatter(with: format)
            return dateFormatter.string(from: object)
        }
    }


    public static var dictionaryKeys: Modifier {
        return CreateModifier.withoutParams("keys") { (object: [String: Any], pInfo: ParsedInfo) -> [String] in
            object.keys.sorted()
        }
    }

    public static var dictionaryValues: Modifier {
        return CreateModifier.withoutParams("values") { (object: [String: Any], pInfo: ParsedInfo) -> [Any] in
            if let values = object as? [String: Double] {
                return values.values.sorted()
            }
            if let values = object as? [String: String] {
                return values.values.sorted()
            }
            return Array(object.values)
        }
    }
    
}

