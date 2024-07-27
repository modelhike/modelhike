//
// DefaultOperatorsLibrary.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct DefaultOperatorsLibrary {

    public static var infixOperators: [InfixOperatorProtocol] {
        return [
            startsWithOperator,
            endsWithOperator,
            containsOperator,
            matchesOperator,
            
            inNumericArrayOperator,
            notInNumericArrayOperator,
            inStringArrayOperator,
            notInStringArrayOperator,

            orOperator,
            andOperator
        ]
    }

    public static var startsWithOperator: InfixOperatorProtocol {
        return CreateOperator.infix("starts-with") { (lhs: String, rhs: String) in lhs.hasPrefix(rhs) }
    }

    public static var endsWithOperator: InfixOperatorProtocol {
        return CreateOperator.infix("ends-with") { (lhs: String, rhs: String) in lhs.hasSuffix(rhs) }
    }

    public static var containsOperator: InfixOperatorProtocol {
        return CreateOperator.infix("contains") { (lhs: String, rhs: String) in lhs.contains(rhs) }
    }

    public static var matchesOperator: InfixOperatorProtocol {
        return CreateOperator.infix("matches") { (lhs: String, rhs: String) in
            if let regex = try? NSRegularExpression(pattern: rhs) {
                let matches = regex.numberOfMatches(in: lhs, range: NSRange(lhs.startIndex..., in: lhs))
                return matches > 0
            }
            return false
        }
    }
    
    public static var inNumericArrayOperator: InfixOperatorProtocol {
        return CreateOperator.infix("in") { (lhs: Double, rhs: [Double]) in rhs.contains(lhs) }
    }

    static var notInNumericArrayOperator: InfixOperatorProtocol {
        return CreateOperator.infix("not-in") { (lhs: Double, rhs: [Double]) in !rhs.contains(lhs) }
    }

    public static var andOperator: InfixOperatorProtocol {
        return CreateOperator.infix("and") { (lhs: Bool, rhs: Bool) in lhs && rhs }
    }

    public static var orOperator: InfixOperatorProtocol {
        return CreateOperator.infix("or") { (lhs: Bool, rhs: Bool) in lhs || rhs }
    }
    
    public static var inStringArrayOperator: InfixOperatorProtocol {
        return CreateOperator.infix("in") { (lhs: String, rhs: [String]) in rhs.contains(lhs) }
    }
    
    static var notInStringArrayOperator: InfixOperatorProtocol {
        return CreateOperator.infix("not-in") { (lhs: String, rhs: [String]) in !rhs.contains(lhs) }
    }
    
}

