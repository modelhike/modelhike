//
//  ModelRegEx.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public enum ModelRegEx {
    
    nonisolated(unsafe)
    public static let whitespace: ZeroOrMore<Substring> = CommonRegEx.whitespace
    
    nonisolated(unsafe)
    public static let variable: Regex<Substring> = CommonRegEx.variable
    
    nonisolated(unsafe)
    public static let nameWithWhitespace: Regex<Substring> = CommonRegEx.nameWithWhitespace

    nonisolated(unsafe)
    public static let variableValue: Regex<Substring> = Regex {
        ChoiceOf {
            CommonRegEx.objectPropertyPattern
            CommonRegEx.variable
        }
    }

    nonisolated(unsafe)
    public static let integer: Regex<Substring> = CommonRegEx.integerPattern

    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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

    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
    static let attribute: Regex<Substring> = Regex {
        variable
        ZeroOrMore(.whitespace)
        
        Optionally {
            ":"
            ZeroOrMore(.whitespace)
            variableValue
        }
    }
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
    static let attributes_Capturing: Regex<(Substring, String, Optional<String>)> = Regex {
        whitespace
        atribute_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
    public static let methodArguments_Capturing: Regex<(Substring, String, String)> = Regex {
        whitespace
        methodArgument_Capturing
        whitespace
        Optionally(",")
        whitespace
    }
    
    nonisolated(unsafe)
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
    
    nonisolated(unsafe)
    public static let moduleName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    nonisolated(unsafe)
    public static let containerName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    nonisolated(unsafe)
    public static let className_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    nonisolated(unsafe)
    public static let uiviewName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
    
    nonisolated(unsafe)
    public static let attachedSectionName_Capturing: Regex<(Substring, String, Optional<String>, Optional<String>)> = container_Member_Capturing
}
