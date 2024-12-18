//
// ModelRegEx.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public enum ModelRegEx {
    
    public static let whitespace: ZeroOrMore<Substring> = CommonRegEx.whitespace
    
    public static let variable: Regex<Substring> = CommonRegEx.variable
    public static let nameWithWhitespace: Regex<Substring> = CommonRegEx.nameWithWhitespace

    public static let variableValue: Regex<Substring> = Regex {
        ChoiceOf {
            CommonRegEx.objectPropertyPattern
            CommonRegEx.variable
        }
    }

    public static let integer: Regex<Substring> = CommonRegEx.integerPattern

    public static let tags: Regex<Substring> = Regex {
        OneOrMore {
            "#"
            variable
            
            Optionally {
                whitespace
                "("
                whitespace
                CommonRegEx.validValue
                whitespace
                ")"
            }
        }
    }
    
    public static let tags_Capturing: Regex<(Substring, String, Optional<String>)> = Regex {
        OneOrMore {
            "#"
            Capture {
                variable
            } transform: { String($0) }
            
            Optionally {
                whitespace
                "("
                whitespace
                Capture {
                    CommonRegEx.validValue
                } transform: { String($0) }
                
                whitespace
                ")"
            }

        }
    }
    
    public static let property_Type: Regex<Substring> = Regex {
        CharacterClass(
            ("A"..."Z"),
            ("a"..."z")
        )
        ZeroOrMore {
            CharacterClass(
                .anyOf("_-@ "),
                ("A"..."Z"),
                ("a"..."z"),
                ("0"..."9")
            )
        }
    }
    
    public static let property_ValidValueSet: Regex<(Substring, String)> = Regex {
        "{"
        Capture {
            ZeroOrMore {
                variable
                Optionally(",")
            }
        } transform: { String($0) }
        "}"
    }


    public static let property_Type_Multiplicity: Regex<(Substring, String)> = Regex {
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
    
    static let attribute: Regex<Substring> = Regex {
        variable
        ZeroOrMore(.whitespace)
        
        Optionally {
            ":"
            ZeroOrMore(.whitespace)
            variableValue
        }
    }
    
    static let attributes: Regex<(Substring, String)> = Regex {
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
    
    static let atribute_Capturing: Regex<(Substring, String, Optional<String>)> = Regex {
        Capture {
            nameWithWhitespace
        } transform: { String($0) }
        
        whitespace
        
        Optionally {
            ":"
            whitespace
            Capture {
                variableValue
            } transform: { String($0) }
        }
    }
    
    static let attributes_Capturing: Regex<(Substring, String, Optional<String>)> = Regex {
        whitespace
        atribute_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    public static let property_Capturing: Regex<(Substring, String, String, Optional<String>, Optional<String>, Optional<String>, Optional<String>)> = Regex {
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
    
    public static let derivedProperty_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = Regex {
        Capture {
            nameWithWhitespace
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
    
    public static let method_Capturing: Regex<(Substring, String, String, Optional<String>, Optional<String>)> = Regex {
        Capture {
            CommonRegEx.functionName
        } transform: { String($0) }
        whitespace
        "("
        whitespace
        Capture {
            ZeroOrMore(.any, .reluctant)
        } transform: { String($0) }
        
        whitespace
        ")"
        
        Optionally {
            whitespace
            ":"
            whitespace
            Capture {
                property_Type
                Optionally("[]")
            } transform: { String($0) }
        }

        whitespace
        
        Optionally {
            Capture {
                tags
            } transform: { String($0) }
        }
        
        CommonRegEx.comments
    }
    
    static let methodArgument_Capturing: Regex<(Substring, String, String)> = Regex {
        Capture {
            variable
        } transform: { String($0) }
        
        whitespace
        ":"
        whitespace
        Capture {
            property_Type
        } transform: { String($0) }
    }
    
    public static let methodArguments_Capturing: Regex<(Substring, String, String)> = Regex {
        whitespace
        methodArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    public static let container_Member_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = Regex {
        Capture {
            nameWithWhitespace
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
    
    public static let moduleName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    public static let containerName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    public static let className_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    public static let uiviewName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    public static let attachedSectionName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
}
