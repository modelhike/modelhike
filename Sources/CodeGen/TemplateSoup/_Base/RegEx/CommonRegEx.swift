//
// CommonRegEx.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public enum CommonRegEx {
    public static let whitespace: ZeroOrMore<Substring> = ZeroOrMore(.whitespace)

    public static let nonWhitespace = Regex {
        OneOrMore(.whitespace.inverted, .eager)
    }

    public static let anything = Regex {
        OneOrMore(.any, .reluctant)
    }
    
    public static let nameWithWhitespace: Regex<Regex<Substring>.RegexOutput> = Regex {
        CharacterClass(
            .anyOf("_"),
            ("A"..."Z"),
            ("a"..."z")
        )
        ZeroOrMore {
            CharacterClass(
                .anyOf("_- "),
                ("A"..."Z"),
                ("a"..."z"),
                ("0"..."9")
            )
        }
    }
    
    public static let variable: Regex<Regex<Substring>.RegexOutput> = Regex {
        CharacterClass(
            .anyOf("_"),
            ("A"..."Z"),
            ("a"..."z")
        )
        ZeroOrMore {
            CharacterClass(
                .anyOf("_-"),
                ("A"..."Z"),
                ("a"..."z"),
                ("0"..."9")
            )
        }
    }

    public static let objectPropertyPattern = Regex {
        variable
        "."
        variable
    }
    
    public static let variableOrObjectProperty = Regex {
        ChoiceOf {
            objectPropertyPattern
            variable
        }
    }
    
    public static let integerPattern = Regex {
        OneOrMore(.digit)
    }

    public static let doublePattern = Regex {
        OneOrMore(.digit)
        "."
        OneOrMore(.digit)
    }

    public static let doubleLiteralPattern_Capturing = Regex {
        Capture {
            doublePattern
        } transform: { Double($0) }
    }
    
    public static let integerLiteralPattern_Capturing = Regex {
        Capture {
            integerPattern
        } transform: { Int($0) }
    }
    
    public static let numberLiteralPattern_Capturing = Regex {
        ChoiceOf {
            doubleLiteralPattern_Capturing
            integerLiteralPattern_Capturing
        }
    }
    
    public static let stringLiteralPattern = Regex {
        ChoiceOf {
            singleQuotedSringLiteral
            doubleQuotedSringLiteral
        }
    }

    static let singleQuotedSringLiteral = Regex {
        "'"
        ZeroOrMore {
            CharacterClass.anyOf("'").inverted
        }
        "'"
    }

    static let doubleQuotedSringLiteral = Regex {
        "\""
        ZeroOrMore {
            CharacterClass.anyOf("\"").inverted
        }
        "\""
    }

    public static let stringLiteralPattern_Capturing = Regex {
        ChoiceOf {
            singleQuotedSringLiteral_Capturing
            doubleQuotedSringLiteral_Capturing
        }
    }

    static let singleQuotedSringLiteral_Capturing = Regex {
        "'"
        Capture {
            ZeroOrMore {
                CharacterClass.anyOf("'").inverted
            }
        } transform: { String($0) }
        "'"
    }

    static let doubleQuotedSringLiteral_Capturing = Regex {
        "\""
        Capture {
            ZeroOrMore {
                CharacterClass.anyOf("\"").inverted
            }
        } transform: { String($0) }

        "\""
    }
    
    public static let functionName = nameWithWhitespace

    public static let functionName_Caaturing = Regex {
        Capture {
            functionName
        } transform: { String($0) }
    }

    public static let validValue = Regex {
        ChoiceOf {
            doublePattern
            integerPattern
            stringLiteralPattern
            
            objectPropertyPattern
            variable
        }
    }
    
    public static let validStringValue = Regex {
        ChoiceOf {
            stringLiteralPattern
            
            objectPropertyPattern
            variable
        }
    }
    
    //public static let validExpression = validValue
    
    static let namedArgument_Capturing = Regex {
        Capture {
            variable
        } transform: { String($0) }
        
        whitespace
        ":"
        whitespace
        Capture {
            validValue
        } transform: { String($0) }
    }
    
    public static let namedArguments_Capturing = Regex {
        whitespace
        namedArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    static let unNamedArgument_Capturing = Regex {
        Capture {
            validValue
        } transform: { String($0) }
    }
    
    public static let unNamedArguments_Capturing = Regex {
        whitespace
        unNamedArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    static let namedArgument = Regex {
        variable
        whitespace
        ":"
        whitespace
        validValue
    }
    
    public static let namedArguments: Regex<Regex<OneOrMore<Substring>.RegexOutput>.RegexOutput> = Regex {
        ZeroOrMore {
            whitespace
            namedArgument
            whitespace
            Optionally(",")
            whitespace
        }
    }
    
    static let unNamedArgument = Regex {
        validValue
    }
    
    public static let unNamedArguments: Regex<Regex<OneOrMore<Substring>.RegexOutput>.RegexOutput> = Regex {
        ZeroOrMore {
            whitespace
            unNamedArgument
            whitespace
            Optionally(",")
            whitespace
        }
    }
    
    public static let functionInvocation_Capturing = Regex {
        Capture {
            functionName
        } transform: { String($0) }
        "("
        whitespace
        Capture {
            ZeroOrMore(.any, .reluctant)
        } transform: { String($0) }

        whitespace
        ")"
    }
    
    public static let functionInvocation_unNamedArgs_Capturing: Regex<Regex<(Substring, String, String)>.RegexOutput> = Regex {
        Capture {
            functionName
        } transform: { String($0) }
        whitespace
        "("
        whitespace
        Capture {
            CommonRegEx.unNamedArguments
        } transform: { String($0) }

        whitespace
        ")"
        
        comments
    }
    
    public static let functionInvocation_namedArgs_Capturing = Regex {
        Capture {
            functionName
        } transform: { String($0) }
        "("
        //whitespace
        Capture {
            namedArguments
        } transform: { String($0) }

        //whitespace
        ")"
    }
    
    public static let functionDeclaration_unNamedArgs_Capturing: Regex<Regex<(Substring, String, String)>.RegexOutput> = functionInvocation_unNamedArgs_Capturing
    
    public static let comments = Regex {
        whitespace
        Optionally {
            TemplateConstants.comments
            ZeroOrMore(.any, .eager)
        }
    }
    
    public static let modifiersForExpression_Capturing: Regex<Regex<(Substring, String?)>.RegexOutput> = Regex {
        whitespace
        Optionally {
            TemplateConstants.modifierSplitInExpression
            CommonRegEx.anythingTillComments_Capturing
            whitespace
        }
    }
    
    public static let anythingTillComments_Capturing: Regex<Regex<Capture<(Substring, String)>.RegexOutput>.RegexOutput> = Regex {
        Capture {
            OneOrMore {
                NegativeLookahead {
                    "//"
                }
                CharacterClass.any
            }
        } transform: { String($0) }
    }
    
//    static func chkType() {
//        if let match = "sfdsf".wholeMatch(of: ModelRegEx.property_Attributes_Capturing) {
//            
//            let (_, _, _, _, _, _, _, _ ,_) = match.output
//        }
//    }
}
