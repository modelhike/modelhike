/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/
//source:  https://github.com/JohnSundell/Publish/blob/master/Sources/Publish/API/StringWrapper.swift

/// Protocol adopted by types that act as type-safe wrappers around strings.
public protocol StringWrapper: CustomStringConvertible,
                               ExpressibleByStringInterpolation,
                               Codable,
                               Hashable,
                               Comparable {
    /// The underlying string value backing this instance.
    var string: String { get }
    /// Initialize a new instance with an underlying string value.
    /// - parameter string: The string to form a new value from.
    init(_ string: String)
}

public extension StringWrapper {
    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.string < rhs.string
    }

    var description: String { string }

    init(stringLiteral value: String) {
        self.init(value)
    }

    init(from decoder: Decoder) throws {
        try self.init(decoder.decodeSingleValue())
    }

    func encode(to encoder: Encoder) throws {
        try encoder.encodeSingleValue(string)
    }
}

public extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }

    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else { return self }
        return String(dropLast(suffix.count))
    }

    func appendingSuffixIfNeeded(_ suffix: String) -> String {
        guard !hasSuffix(suffix) else { return self }
        return appending(suffix)
    }
}
