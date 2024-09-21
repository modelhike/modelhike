//
// ModelRegEx.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public enum ModelRegEx {
    
    public static let whitespace: ZeroOrMore<Substring> = CommonRegEx.whitespace
    
    public static let variable: Regex<Regex<Substring>.RegexOutput> = CommonRegEx.variable
    public static let nameWithWhitespace: Regex<Regex<Substring>.RegexOutput> = Regex {
        CharacterClass(
            .anyOf("_ "),
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

    public static let variableValue = Regex {
        ChoiceOf {
            CommonRegEx.objectPropertyPattern
            CommonRegEx.variable
        }
    }

    public static let integer = CommonRegEx.integerPattern

    public static let tags: Regex<Regex<OneOrMore<Substring>.RegexOutput>.RegexOutput> = Regex {
        OneOrMore {
            "#"
            variable
        }
    }
    
    public static let tags_Capturing = Regex {
        OneOrMore {
            "#"
            Capture {
                variable
            } transform: { String($0) }
        }
    }
    
    public static let property_Type: Regex<Regex<Substring>.RegexOutput> = Regex {
        CharacterClass(
            ("A"..."Z"),
            ("a"..."z")
        )
        ZeroOrMore {
            CharacterClass(
                .anyOf("_-@"),
                ("A"..."Z"),
                ("a"..."z"),
                ("0"..."9")
            )
        }
        Optionally {
            "["
            
            "]"
        }
    }
    
    public static let property_ValidValueSet: Regex<Regex<Optionally<(Substring, String?)>.RegexOutput>.RegexOutput> = Regex {
        Optionally {
            "{"
            Capture {
                ZeroOrMore {
                    variable
                    Optionally(",")
                }
            } transform: { String($0) }
            "}"
        }
    }


    public static let property_Type_Multiplicity: Regex<Regex<(Substring, String)>.RegexOutput> = Regex {
        "["
        Capture {
            Optionally {
                integer
                ".."
            }
            "*"
        } transform: { String($0) }
        "]"
    }
    
    static let attribute: Regex<Regex<Substring>.RegexOutput> = Regex {
        variable
        ZeroOrMore(.whitespace)
        
        Optionally {
            ":"
            ZeroOrMore(.whitespace)
            variableValue
        }
    }
    
    static let attributes: Regex<Regex<(Substring, String)>.RegexOutput> = Regex {
        whitespace
        "("
        Capture {
            ZeroOrMore {
                whitespace
                attribute
                whitespace
                Optionally(",")
                whitespace
            }
        } transform: { String($0) }
        ")"
        whitespace
    }
    
    static let atribute_Capturing = Regex {
        Capture {
            variable
        } transform: { String($0) }
        
        ZeroOrMore(.whitespace)
        
        Optionally {
            ":"
            ZeroOrMore(.whitespace)
            Capture {
                variableValue
            } transform: { String($0) }
        }
    }
    
    static let attributes_Capturing: Regex<Regex<ZeroOrMore<(Substring, String?, String??)>.RegexOutput>.RegexOutput> = Regex {
        ZeroOrMore {
            ZeroOrMore(.whitespace)
            atribute_Capturing
            ZeroOrMore(.whitespace)
            Optionally(",")
            ZeroOrMore(.whitespace)
        }
    }
    
    public static let property_Capturing: Regex<Regex<(Substring, String, String, String?, String?, String??, String?)>.RegexOutput> = Regex {
        Capture {
            nameWithWhitespace
        } transform: { String($0) }
        
        whitespace
        ":"
        
        whitespace
        Capture {
            property_Type
        } transform: { String($0) }
        whitespace
        
        Optionally {
            property_Type_Multiplicity
        }
        
        Optionally {
            attributes
        }
        
        Optionally {
            property_ValidValueSet
        }
        
        Optionally {
            Capture {
                tags
            } transform: { String($0) }
        }
    
        CommonRegEx.comments
    }
    
    public static let container_Member_Capturing: Regex<(Substring, String, String?, String?)> = Regex {
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
                
        Optionally {
            attributes
        }
        
        Optionally {
            Capture {
                tags
            } transform: { String($0) }
        }
    
        CommonRegEx.comments
    }
}
