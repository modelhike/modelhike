//
//  ModelConstants.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public enum ModelConstants {
    public static let Member_Optional = "-"
    public static let Member_Optional2 = "_" //underscore; sometimes mistakenly user gives this
    public static let Member_Mandatory = "*"
    public static let Member_Conditional = "*?"
    
    public static let Member_Calculated = "="
    public static let Member_Derived_For_Dto = "."
    
    public static let Member_Method = "~"
    public static let MethodUnderlineChar = "~"

    public static let External_Import_File = "+"
    public static let Container_Member = "+"

    public static let AttachedSection = "#"
    public static let AttachedSubSection = "##"

    public static let Annotation_Start = "@"
    public static let Annotation_Split = "::"

    public static let NameUnderlineChar = "="
    public static let NameOverlineChar = "="
    public static let NamePrefixLineChar = "="

    public static let UIViewUnderlineChar = "~"

    public static let ModelFile_Extension = "modelhike"
    public static let ConfigFile_Extension = "tconfig"
}
