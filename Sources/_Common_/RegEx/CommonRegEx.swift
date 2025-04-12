//
//  CommonRegEx.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public enum CommonRegEx {
    public static let whitespace: ZeroOrMore<Substring> = ZeroOrMore(.whitespace)

    public static let nonWhitespace: Regex<Substring> = Regex {
        OneOrMore(.whitespace.inverted, .eager)
    }

    public static let anything: Regex<Substring> = Regex {
        OneOrMore(.any, .reluctant)
    }
    
    public static let nameWithWhitespace: Regex<Substring> = Regex {
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
    
    public static let variable: Regex<Substring> = Regex {
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

    public static let objectPropertyPattern: Regex<Substring> = Regex {
        CharacterClass(
            .anyOf("@_"), //'@' is the prefix used for pre-defined variables
            ("A"..."Z"),
            ("a"..."z")
        )
        ZeroOrMore {
            CharacterClass(
                .anyOf("._-"), //includes for operator for property names
                ("A"..."Z"),
                ("a"..."z"),
                ("0"..."9")
            )
        }
    }
    
    public static let variableOrObjectProperty: Regex<Substring> = Regex {
        ChoiceOf {
            objectPropertyPattern
            variable
        }
    }
    
    public static let integerPattern: Regex<Substring> = Regex {
        OneOrMore(.digit)
    }

    public static let doublePattern: Regex<Substring> = Regex {
        OneOrMore(.digit)
        "."
        OneOrMore(.digit)
    }

    public static let doubleLiteralPattern_Capturing: Regex<(Substring, Optional<Double>)> = Regex {
        Capture {
            doublePattern
        } transform: { Double($0) }
    }
    
    public static let integerLiteralPattern_Capturing: Regex<(Substring, Optional<Int>)> = Regex {
        Capture {
            integerPattern
        } transform: { Int($0) }
    }
    
    public static let numberLiteralPattern_Capturing: Regex<(Substring, Optional<Optional<Double>>, Optional<Optional<Int>>)> = Regex {
        ChoiceOf {
            doubleLiteralPattern_Capturing
            integerLiteralPattern_Capturing
        }
    }
    
    public static let stringLiteralPattern: Regex<Substring> = Regex {
        ChoiceOf {
            singleQuotedSringLiteral
            doubleQuotedSringLiteral
        }
    }

    static let singleQuotedSringLiteral: Regex<Substring> = Regex {
        "'"
        ZeroOrMore {
            CharacterClass.anyOf("'").inverted
        }
        "'"
    }

    static let doubleQuotedSringLiteral: Regex<Substring> = Regex {
        "\""
        ZeroOrMore {
            CharacterClass.anyOf("\"").inverted
        }
        "\""
    }

    public static let stringLiteralPattern_Capturing: Regex<(Substring, Optional<String>, Optional<String>)> = Regex {
        ChoiceOf {
            singleQuotedSringLiteral_Capturing
            doubleQuotedSringLiteral_Capturing
        }
    }

    static let singleQuotedSringLiteral_Capturing: Regex<(Substring, String)> = Regex {
        "'"
        Capture {
            ZeroOrMore {
                CharacterClass.anyOf("'").inverted
            }
        } transform: { String($0) }
        "'"
    }

    static let doubleQuotedSringLiteral_Capturing: Regex<(Substring, String)> = Regex {
        "\""
        Capture {
            ZeroOrMore {
                CharacterClass.anyOf("\"").inverted
            }
        } transform: { String($0) }

        "\""
    }
    
    public static let functionName: Regex<Substring> = nameWithWhitespace

    public static let functionName_Capturing: Regex<(Substring, String)> = Regex {
        Capture {
            functionName
        } transform: { String($0) }
    }

    public static let validValue: Regex<Substring> = Regex {
        ChoiceOf {
            doublePattern
            integerPattern
            stringLiteralPattern
            
            objectPropertyPattern
            variable
        }
    }
    
    public static let validStringValue: Regex<Substring> = Regex {
        ChoiceOf {
            stringLiteralPattern
            
            objectPropertyPattern
            variable
        }
    }
    
    //public static let validExpression = validValue
    
    static let namedParameter_Capturing: Regex<(Substring, String, String)> = Regex {
        Capture {
            variable
        } transform: { String($0) }
        
        whitespace
        ":"
        whitespace
        Capture {
            ModelRegEx.property_Type
            Optionally("[]")
        } transform: { String($0) }
    }
    
    public static let namedParameters_Capturing: Regex<(Substring, String, String)> = Regex {
        whitespace
        namedParameter_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    static let namedArgument_Capturing: Regex<(Substring, String, String)> = Regex {
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
    
    public static let namedArguments_Capturing: Regex<(Substring, String, String)> = Regex {
        whitespace
        namedArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    static let unNamedArgument_Capturing: Regex<(Substring, String)> = Regex {
        Capture {
            validValue
        } transform: { String($0) }
    }
    
    public static let unNamedArguments_Capturing: Regex<(Substring, String)> = Regex {
        whitespace
        unNamedArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    static let namedArgument: Regex<Substring> = Regex {
        variable
        whitespace
        ":"
        whitespace
        validValue
    }
    
    public static let namedArguments: Regex<Substring> = Regex {
        ZeroOrMore {
            whitespace
            namedArgument
            whitespace
            Optionally(",")
            whitespace
        }
    }
    
    static let unNamedArgument: Regex<Substring> = Regex {
        validValue
    }
    
    public static let unNamedArguments: Regex<Substring> = Regex {
        ZeroOrMore {
            whitespace
            unNamedArgument
            whitespace
            Optionally(",")
            whitespace
        }
    }
    
    public static let functionInvocation_Capturing: Regex<(Substring, String, String)> = Regex {
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
    
    public static let functionInvocation_unNamedArgs_Capturing: Regex<(Substring, String, String)> = Regex {
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
    
    public static let functionInvocation_namedArgs_Capturing: Regex<(Substring, String, String)> = Regex {
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
    
    public static let functionDeclaration_unNamedArgs_Capturing: Regex<(Substring, String, String)> = functionInvocation_unNamedArgs_Capturing
    
    public static let comments = Regex {
        whitespace
        Optionally {
            TemplateConstants.comments
            ZeroOrMore(.any, .eager)
        }
    }
    
    public static let modifiersForExpression_Capturing: Regex<(Substring, Optional<String>)> = Regex {
        whitespace
        Optionally {
            TemplateConstants.modifierSplitInExpression
            CommonRegEx.anythingTillComments_Capturing
            whitespace
        }
    }
    
    public static let anythingTillComments_Capturing: Regex<(Substring, String)> = Regex {
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
