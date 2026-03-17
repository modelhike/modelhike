//
//  Constraint.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum ConstraintUnaryOperator: String, Equatable, Sendable {
    case not = "!"
    case positive = "+"
    case negative = "-"
    case bitwiseNot = "~"
}

public enum ConstraintBinaryOperator: String, Equatable, Sendable {
    case equals = "=="
    case notEquals = "!="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case and = "&&"
    case or = "||"
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
    case like = "like"
    case inList = "in"
}

public indirect enum ConstraintExpr: Equatable, Sendable {
    case identifier(String)
    case integer(Int)
    case double(Double)
    case string(String)
    case boolean(Bool)
    case null
    case function(name: String, arguments: [ConstraintExpr])
    case list([ConstraintExpr])
    case unary(op: ConstraintUnaryOperator, expr: ConstraintExpr)
    case binary(lhs: ConstraintExpr, op: ConstraintBinaryOperator, rhs: ConstraintExpr)
    case between(value: ConstraintExpr, lower: ConstraintExpr, upper: ConstraintExpr)
    case grouped(ConstraintExpr)
}

public struct Constraint: Equatable, Sendable {
    public let name: String?
    public let expr: ConstraintExpr

    public var isNamed: Bool {
        name != nil
    }

    public init(name: String? = nil, expr: ConstraintExpr) {
        self.name = name?.trim()
        self.expr = expr
    }
}

public actor Constraints: Sendable {
    private var items: [Constraint] = []

    public func add(_ constraint: Constraint) {
        items.append(constraint)
    }

    public func set(_ constraints: [Constraint]) {
        items = constraints
    }

    public func snapshot() -> [Constraint] {
        items
    }

    public func has(_ name: String) -> Bool {
        get(name) != nil
    }

    public func get(_ name: String) -> Constraint? {
        let key = name.lowercased()
        return items.first { $0.name?.lowercased() == key }
    }

    public func getString(_ name: String) -> String? {
        guard let constraint = get(name) else { return nil }
        return ConstraintRenderer.renderValue(of: constraint)
    }

    public subscript(key: String) -> Sendable? {
        get {
            getString(key)
        }
    }

    public init() {}
}

public enum ConstraintRenderer {
    public static func render(_ constraint: Constraint) -> String {
        if let name = constraint.name {
            return "\(name) = \(render(constraint.expr))"
        }
        return render(constraint.expr)
    }

    public static func renderValue(of constraint: Constraint) -> String {
        render(constraint.expr)
    }

    public static func render(_ expr: ConstraintExpr) -> String {
        switch expr {
        case .identifier(let name):
            return name
        case .integer(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return quote(value)
        case .boolean(let value):
            return value ? "true" : "false"
        case .null:
            return "nil"
        case .function(let name, let arguments):
            return "\(name)(\(arguments.map(render).joined(separator: ", ")))"
        case .list(let values):
            return "[" + values.map(render).joined(separator: ", ") + "]"
        case .unary(let op, let inner):
            return op.rawValue + renderUnaryOperand(inner)
        case .binary(let lhs, let op, let rhs):
            return "\(renderBinaryOperand(lhs, parent: op, isRight: false)) \(op.rawValue) \(renderBinaryOperand(rhs, parent: op, isRight: true))"
        case .between(let value, let lower, let upper):
            return "\(render(value)) between \(render(lower)) and \(render(upper))"
        case .grouped(let inner):
            return "(\(render(inner)))"
        }
    }

    private static func quote(_ string: String) -> String {
        "\"" + string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    private static func renderUnaryOperand(_ expr: ConstraintExpr) -> String {
        switch expr {
        case .binary, .between:
            return "(\(render(expr)))"
        default:
            return render(expr)
        }
    }

    private static func renderBinaryOperand(
        _ expr: ConstraintExpr,
        parent: ConstraintBinaryOperator,
        isRight: Bool
    ) -> String {
        switch expr {
        case .binary(_, let child, _):
            if precedence(of: child) < precedence(of: parent) {
                return "(\(render(expr)))"
            }
            if isRight && precedence(of: child) == precedence(of: parent) &&
                (parent == .subtract || parent == .divide) {
                return "(\(render(expr)))"
            }
            return render(expr)
        case .between:
            return "(\(render(expr)))"
        default:
            return render(expr)
        }
    }

    private static func precedence(of op: ConstraintBinaryOperator) -> Int {
        switch op {
        case .or:
            return 1
        case .and:
            return 2
        case .equals, .notEquals, .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual, .like, .inList:
            return 3
        case .add, .subtract:
            return 4
        case .multiply, .divide, .modulo:
            return 5
        }
    }
}

public enum ConstraintParseError: Error, Equatable, Sendable {
    case expectedToken(String)
    case unexpectedToken(String)
    case unexpectedEndOfInput
    case unterminatedStringLiteral
}

public enum ConstraintParser {
    public static func parseList(_ source: String) throws -> [Constraint] {
        var parser = Parser(tokens: try Lexer.tokenize(source))
        return try parser.parseConstraints()
    }

    private enum Token: Equatable {
        case identifier(String)
        case integer(String)
        case double(String)
        case string(String)
        case boolean(Bool)
        case null
        case leftParen
        case rightParen
        case leftBracket
        case rightBracket
        case comma
        case assignment
        case oper(Operator)
        case eof

        var description: String {
            switch self {
            case .identifier(let value), .integer(let value), .double(let value), .string(let value):
                return value
            case .boolean(let value):
                return value ? "true" : "false"
            case .null:
                return "nil"
            case .leftParen:
                return "("
            case .rightParen:
                return ")"
            case .leftBracket:
                return "["
            case .rightBracket:
                return "]"
            case .comma:
                return ","
            case .assignment:
                return "="
            case .oper(let oper):
                return oper.rawValue
            case .eof:
                return "<eof>"
            }
        }
    }

    private enum Operator: String, Equatable {
        case equals = "=="
        case notEquals = "!="
        case greaterThan = ">"
        case greaterThanOrEqual = ">="
        case lessThan = "<"
        case lessThanOrEqual = "<="
        case and = "&&"
        case or = "||"
        case plus = "+"
        case minus = "-"
        case multiply = "*"
        case divide = "/"
        case modulo = "%"
        case not = "!"
        case bitwiseNot = "~"
        case like = "like"
        case inList = "in"
        case between = "between"
        case isValue = "is"
    }

    private enum Lexer {
        static func tokenize(_ source: String) throws -> [Token] {
            var tokens: [Token] = []
            var index = source.startIndex

            func advance(_ current: inout String.Index) {
                current = source.index(after: current)
            }

            while index < source.endIndex {
                let char = source[index]

                if char.isWhitespace {
                    advance(&index)
                    continue
                }

                switch char {
                case "(":
                    tokens.append(.leftParen)
                    advance(&index)
                case ")":
                    tokens.append(.rightParen)
                    advance(&index)
                case "[":
                    tokens.append(.leftBracket)
                    advance(&index)
                case "]":
                    tokens.append(.rightBracket)
                    advance(&index)
                case ",":
                    tokens.append(.comma)
                    advance(&index)
                case "=":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "=" {
                        tokens.append(.oper(.equals))
                        index = source.index(after: next)
                    } else {
                        tokens.append(.assignment)
                        advance(&index)
                    }
                case "!":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "=" {
                        tokens.append(.oper(.notEquals))
                        index = source.index(after: next)
                    } else {
                        tokens.append(.oper(.not))
                        advance(&index)
                    }
                case ">":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "=" {
                        tokens.append(.oper(.greaterThanOrEqual))
                        index = source.index(after: next)
                    } else {
                        tokens.append(.oper(.greaterThan))
                        advance(&index)
                    }
                case "<":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "=" {
                        tokens.append(.oper(.lessThanOrEqual))
                        index = source.index(after: next)
                    } else if next < source.endIndex, source[next] == ">" {
                        tokens.append(.oper(.notEquals))
                        index = source.index(after: next)
                    } else {
                        tokens.append(.oper(.lessThan))
                        advance(&index)
                    }
                case "&":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "&" {
                        tokens.append(.oper(.and))
                        index = source.index(after: next)
                    } else {
                        throw ConstraintParseError.unexpectedToken(String(char))
                    }
                case "|":
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "|" {
                        tokens.append(.oper(.or))
                        index = source.index(after: next)
                    } else {
                        throw ConstraintParseError.unexpectedToken(String(char))
                    }
                case "+":
                    tokens.append(.oper(.plus))
                    advance(&index)
                case "-":
                    tokens.append(.oper(.minus))
                    advance(&index)
                case "*":
                    tokens.append(.oper(.multiply))
                    advance(&index)
                case "/":
                    tokens.append(.oper(.divide))
                    advance(&index)
                case "%":
                    tokens.append(.oper(.modulo))
                    advance(&index)
                case "~":
                    tokens.append(.oper(.bitwiseNot))
                    advance(&index)
                case "\"", "'":
                    let quote = char
                    advance(&index)
                    var value = ""
                    var isClosed = false

                    while index < source.endIndex {
                        let current = source[index]
                        if current == "\\" {
                            let next = source.index(after: index)
                            if next < source.endIndex {
                                value.append(source[next])
                                index = source.index(after: next)
                                continue
                            }
                        }
                        if current == quote {
                            isClosed = true
                            advance(&index)
                            break
                        }
                        value.append(current)
                        advance(&index)
                    }

                    if isClosed == false {
                        throw ConstraintParseError.unterminatedStringLiteral
                    }
                    tokens.append(.string(value))
                default:
                    if char.isNumber {
                        let start = index
                        advance(&index)
                        while index < source.endIndex, source[index].isNumber {
                            advance(&index)
                        }

                        if index < source.endIndex, source[index] == "." {
                            let next = source.index(after: index)
                            if next < source.endIndex, source[next].isNumber {
                                advance(&index)
                                while index < source.endIndex, source[index].isNumber {
                                    advance(&index)
                                }
                                tokens.append(.double(String(source[start..<index])))
                            } else {
                                tokens.append(.integer(String(source[start..<index])))
                            }
                        } else {
                            tokens.append(.integer(String(source[start..<index])))
                        }
                        continue
                    }

                    if isIdentifierStart(char) {
                        let start = index
                        advance(&index)
                        while index < source.endIndex, isIdentifierPart(source[index]) {
                            advance(&index)
                        }
                        let raw = String(source[start..<index])
                        switch raw.lowercased() {
                        case "and":
                            tokens.append(.oper(.and))
                        case "or":
                            tokens.append(.oper(.or))
                        case "not":
                            tokens.append(.oper(.not))
                        case "like":
                            tokens.append(.oper(.like))
                        case "in":
                            tokens.append(.oper(.inList))
                        case "between":
                            tokens.append(.oper(.between))
                        case "is":
                            tokens.append(.oper(.isValue))
                        case "true":
                            tokens.append(.boolean(true))
                        case "false":
                            tokens.append(.boolean(false))
                        case "null", "nil":
                            tokens.append(.null)
                        default:
                            tokens.append(.identifier(raw))
                        }
                        continue
                    }

                    throw ConstraintParseError.unexpectedToken(String(char))
                }
            }

            tokens.append(.eof)
            return tokens
        }

        private static func isIdentifierStart(_ char: Character) -> Bool {
            char == "_" || char == "@" || char.isLetter
        }

        private static func isIdentifierPart(_ char: Character) -> Bool {
            char == "_" || char == "@" || char == "." || char == "-" || char.isLetter || char.isNumber
        }
    }

    private struct Parser {
        let tokens: [Token]
        var index: Int = 0

        mutating func parseConstraints() throws -> [Constraint] {
            var result: [Constraint] = []

            while isAtEnd == false {
                result.append(try parseConstraint())
                if match(.comma) == false {
                    break
                }
            }

            guard isAtEnd else {
                throw ConstraintParseError.unexpectedToken(peek.description)
            }
            return result
        }

        mutating func parseConstraint() throws -> Constraint {
            if case .identifier(let name) = peek,
               peekNext == .assignment {
                advance()
                advance()
                return Constraint(name: name, expr: try parseExpression())
            }

            return Constraint(expr: try parseExpression())
        }

        mutating func parseExpression() throws -> ConstraintExpr {
            try parseOr()
        }

        mutating func parseOr() throws -> ConstraintExpr {
            var expr = try parseAnd()
            while match(.oper(.or)) {
                let rhs = try parseAnd()
                expr = .binary(lhs: expr, op: .or, rhs: rhs)
            }
            return expr
        }

        mutating func parseAnd() throws -> ConstraintExpr {
            var expr = try parseComparison()
            while match(.oper(.and)) {
                let rhs = try parseComparison()
                expr = .binary(lhs: expr, op: .and, rhs: rhs)
            }
            return expr
        }

        mutating func parseComparison() throws -> ConstraintExpr {
            var expr = try parseAdditive()

            while true {
                if match(.oper(.equals)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .equals, rhs: rhs)
                } else if match(.oper(.notEquals)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .notEquals, rhs: rhs)
                } else if match(.oper(.greaterThan)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .greaterThan, rhs: rhs)
                } else if match(.oper(.greaterThanOrEqual)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .greaterThanOrEqual, rhs: rhs)
                } else if match(.oper(.lessThan)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .lessThan, rhs: rhs)
                } else if match(.oper(.lessThanOrEqual)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .lessThanOrEqual, rhs: rhs)
                } else if match(.oper(.like)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .like, rhs: rhs)
                } else if match(.oper(.inList)) {
                    let rhs = try parseAdditive()
                    expr = .binary(lhs: expr, op: .inList, rhs: rhs)
                } else if match(.oper(.between)) {
                    let lower = try parseAdditive()
                    try consume(.oper(.and))
                    let upper = try parseAdditive()
                    expr = .between(value: expr, lower: lower, upper: upper)
                } else if match(.oper(.isValue)) {
                    if match(.oper(.not)) {
                        try consume(.null)
                        expr = .binary(lhs: expr, op: .notEquals, rhs: .null)
                    } else {
                        try consume(.null)
                        expr = .binary(lhs: expr, op: .equals, rhs: .null)
                    }
                } else {
                    break
                }
            }

            return expr
        }

        mutating func parseAdditive() throws -> ConstraintExpr {
            var expr = try parseMultiplicative()
            while true {
                if match(.oper(.plus)) {
                    let rhs = try parseMultiplicative()
                    expr = .binary(lhs: expr, op: .add, rhs: rhs)
                } else if match(.oper(.minus)) {
                    let rhs = try parseMultiplicative()
                    expr = .binary(lhs: expr, op: .subtract, rhs: rhs)
                } else {
                    break
                }
            }
            return expr
        }

        mutating func parseMultiplicative() throws -> ConstraintExpr {
            var expr = try parseUnary()
            while true {
                if match(.oper(.multiply)) {
                    let rhs = try parseUnary()
                    expr = .binary(lhs: expr, op: .multiply, rhs: rhs)
                } else if match(.oper(.divide)) {
                    let rhs = try parseUnary()
                    expr = .binary(lhs: expr, op: .divide, rhs: rhs)
                } else if match(.oper(.modulo)) {
                    let rhs = try parseUnary()
                    expr = .binary(lhs: expr, op: .modulo, rhs: rhs)
                } else {
                    break
                }
            }
            return expr
        }

        mutating func parseUnary() throws -> ConstraintExpr {
            if match(.oper(.not)) {
                return .unary(op: .not, expr: try parseUnary())
            }
            if match(.oper(.minus)) {
                return .unary(op: .negative, expr: try parseUnary())
            }
            if match(.oper(.plus)) {
                return .unary(op: .positive, expr: try parseUnary())
            }
            if match(.oper(.bitwiseNot)) {
                return .unary(op: .bitwiseNot, expr: try parseUnary())
            }
            return try parsePrimary()
        }

        mutating func parsePrimary() throws -> ConstraintExpr {
            switch peek {
            case .identifier(let name):
                advance()
                if match(.leftParen) {
                    var arguments: [ConstraintExpr] = []
                    if check(.rightParen) == false {
                        repeat {
                            arguments.append(try parseExpression())
                        } while match(.comma)
                    }
                    try consume(.rightParen)
                    return .function(name: name, arguments: arguments)
                }
                return .identifier(name)
            case .integer(let value):
                advance()
                return .integer(Int(value) ?? 0)
            case .double(let value):
                advance()
                return .double(Double(value) ?? 0)
            case .string(let value):
                advance()
                return .string(value)
            case .boolean(let value):
                advance()
                return .boolean(value)
            case .null:
                advance()
                return .null
            case .leftBracket:
                advance()
                var items: [ConstraintExpr] = []
                if check(.rightBracket) == false {
                    repeat {
                        items.append(try parseExpression())
                    } while match(.comma)
                }
                try consume(.rightBracket)
                return .list(items)
            case .leftParen:
                advance()
                let expr = try parseExpression()
                try consume(.rightParen)
                return .grouped(expr)
            case .eof:
                throw ConstraintParseError.unexpectedEndOfInput
            default:
                throw ConstraintParseError.unexpectedToken(peek.description)
            }
        }

        private var isAtEnd: Bool {
            peek == .eof
        }

        private var peek: Token {
            tokens[index]
        }

        private var peekNext: Token {
            let nextIndex = min(index + 1, tokens.count - 1)
            return tokens[nextIndex]
        }

        @discardableResult
        private mutating func advance() -> Token {
            let current = tokens[index]
            if index < tokens.count - 1 {
                index += 1
            }
            return current
        }

        private mutating func match(_ token: Token) -> Bool {
            guard check(token) else { return false }
            advance()
            return true
        }

        private func check(_ token: Token) -> Bool {
            peek == token
        }

        private mutating func consume(_ token: Token) throws {
            guard match(token) else {
                throw ConstraintParseError.expectedToken(token.description)
            }
        }
    }
}
