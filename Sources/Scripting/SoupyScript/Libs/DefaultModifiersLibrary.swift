//
//  DefaultModifiersLibrary.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct DefaultModifiersLibrary {

    public static func modifiers() async -> [Modifier] {
        return await [
            length(),
            capitalise(),
            lowercase(),
            uppercase(),
            lowercaseFirst(),
            uppercaseFirst(),
            trim(),
            
            replacewith(),
            
            urlEncode(),
            urlDecode(),
            nl2br(),

            absoluteValue(),

            minFunction(),
            maxFunction(),
            sumFunction(),
            sqrtFunction(),
            roundFunction(),
            averageFunction(),

            arrayCountFunction(),
            arraySortFunction(),
            arrayReverseFunction(),
            arrayMinFunction(),
            arrayMaxFunction(),
            arrayFirstFunction(),
            arrayLastFunction(),
            arrayJoinFunction(),
            arraySumFunction(),
            arrayAverageFunction(),

            dictionaryCountFunction(),
            dictionaryKeys(),
            dictionaryValues(),

            dateFactory(),
            dateFormat()
        ]
    }


    static func length() async -> Modifier {
        return await CreateModifier.withoutParams("length") { (value: String, pInfo: ParsedInfo) -> Double? in Double(value.count) }
    }
    
    public static func capitalise() async -> Modifier {
        return await CreateModifier.withoutParams("capitalise") { (value: String, pInfo: ParsedInfo) -> String? in value.capitalized }
    }

    public static func lowercase() async -> Modifier {
        return await CreateModifier.withoutParams("lowercase") { (value: String, pInfo: ParsedInfo) -> String? in value.lowercased() }
    }

    public static func uppercase() async -> Modifier {
        return await CreateModifier.withoutParams("uppercase") { (value: String, pInfo: ParsedInfo) -> String? in value.uppercased() }
    }

    public static func lowercaseFirst() async -> Modifier {
        return await CreateModifier.withoutParams("lowerFirst") { (value: String, pInfo: ParsedInfo) -> String? in
            guard let first = value.first else { return nil }
            return String(first).lowercased() + value[value.index(value.startIndex, offsetBy: 1)...]
        }
    }

    public static func uppercaseFirst() async -> Modifier {
        return await CreateModifier.withoutParams("upperFirst") { (value: String, pInfo: ParsedInfo) -> String? in
            guard let _ = value.first else { return nil }
            return value.uppercasedFirst()
        }
    }

    public static func trim() async -> Modifier {
        return await CreateModifier.withoutParams("trim") { (value: String, pInfo: ParsedInfo) -> String? in value.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    public static func replacewith() async -> Modifier {
        return await CreateModifier.withParams("replace") { (value: String, arguments: [Sendable], pInfo: ParsedInfo) throws -> String? in
            if arguments.count != 2 { throw TemplateSoup_ParsingError.modifierInvalidArguments("replace", pInfo) }
            
            guard let replaceFrom = arguments.first as? String,
                  let replaceWith = arguments[1] as? String else { return nil }
            return value.replacingOccurrences(of: replaceFrom, with: replaceWith)
        }
    }
    
    public static func urlEncode() async -> Modifier {
        return await CreateModifier.withoutParams("urlEncode") { (value: String, pInfo: ParsedInfo) -> String? in value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) }
    }

    public static func urlDecode() async -> Modifier {
        return await CreateModifier.withoutParams("urlDecode") { (value: String, pInfo: ParsedInfo) -> String? in value.removingPercentEncoding }
    }

    public static func nl2br() async -> Modifier {
        return await CreateModifier.withoutParams("nl2br") { (value: String, pInfo: ParsedInfo) -> String? in value
            .replacingOccurrences(of: "\r\n", with: "<br/>")
            .replacingOccurrences(of: "\n", with: "<br/>")
        }
    }

    public static func absoluteValue() async -> Modifier {
        return await CreateModifier.withoutParams("abs") { (value: Double, pInfo: ParsedInfo) -> Double? in abs(value) }
    }

    public static func minFunction() async -> Modifier {
        return await CreateModifier.withoutParams("min") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.min()
        }
    }

    public static func maxFunction() async -> Modifier {
        return await CreateModifier.withoutParams("max") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.max()
        }
    }

    public static func arraySortFunction() async -> Modifier {
        return await CreateModifier.withoutParams("sort") { (object: [Double], pInfo: ParsedInfo) -> [Double]? in object.sorted() }
    }

    public static func arrayReverseFunction() async -> Modifier {
        return await CreateModifier.withoutParams("reverse") { (object: [Double], pInfo: ParsedInfo) -> [Double]? in object.reversed() }
    }

    public static func arrayMinFunction() async -> Modifier {
        return await CreateModifier.withoutParams("min") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.min() }
    }

    public static func arrayMaxFunction() async -> Modifier {
        return await CreateModifier.withoutParams("max") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.max() }
    }

    public static func arrayFirstFunction() async -> Modifier {
        return await CreateModifier.withoutParams("first") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.first }
    }

    public static func arrayLastFunction() async -> Modifier {
        return await CreateModifier.withoutParams("last") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.last }
    }

    public static func arrayJoinFunction() async -> Modifier {
        return await CreateModifier.withParams("join") { (object: [String], arguments: [Sendable], pInfo: ParsedInfo) -> String? in
            guard let separator = arguments.first as? String else { return nil }
            return object.joined(separator: separator)
        }
    }

    public static func arraySumFunction() async -> Modifier {
        return await CreateModifier.withoutParams("sum") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.reduce(0, +) }
    }

    public static func arrayAverageFunction() async -> Modifier {
        return await CreateModifier.withoutParams("avg") { (object: [Double], pInfo: ParsedInfo) -> Double? in object.reduce(0, +) / Double(object.count) }
    }

    public static func arrayCountFunction() async -> Modifier {
        return await CreateModifier.withoutParams("count") { (object: [Double], pInfo: ParsedInfo) -> Double? in Double(object.count) }
    }

    public static func dictionaryCountFunction() async -> Modifier {
        return await CreateModifier.withoutParams("count") { (object: [String: Sendable], pInfo: ParsedInfo) -> Double? in Double(object.count) }
    }

    public static func sumFunction() async -> Modifier {
        return await CreateModifier.withoutParams("sum") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.reduce(0, +)
        }
    }

    public static func averageFunction() async -> Modifier {
        return await CreateModifier.withoutParams("avg") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let arguments = arguments as? [Double] else { return nil }
            return arguments.reduce(0, +) / Double(arguments.count)
        }
    }

    public static func sqrtFunction() async -> Modifier {
        return await CreateModifier.withoutParams("sqrt") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let value = arguments.first as? Double else { return nil }
            return sqrt(value)
        }
    }

    public static func roundFunction() async -> Modifier {
        return await CreateModifier.withoutParams("round") { (arguments: [Sendable], pInfo: ParsedInfo) -> Double? in
            guard let value = arguments.first as? Double else { return nil }
            return round(value)
        }
    }

    public static func dateFactory() async -> Modifier {
        return await CreateModifier.withoutParams("Date") { (arguments: [Sendable], pInfo: ParsedInfo) -> Date? in
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

    public static func dateFormat() async -> Modifier {
        return await CreateModifier.withParams("format") { (object: Date, arguments: [Sendable], pInfo: ParsedInfo) -> String? in
            guard let format = arguments.first as? String else { return nil }
            let dateFormatter = DateFormatter(with: format)
            return dateFormatter.string(from: object)
        }
    }


    public static func dictionaryKeys() async -> Modifier {
        return await CreateModifier.withoutParams("keys") { (object: [String: Sendable], pInfo: ParsedInfo) -> [String] in
            object.keys.sorted()
        }
    }

    public static func dictionaryValues() async -> Modifier {
        return await CreateModifier.withoutParams("values") { (object: [String: Sendable], pInfo: ParsedInfo) -> [Sendable] in
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

