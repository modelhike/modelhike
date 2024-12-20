//
// SetObjectAttributeStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class SetObjectAttributeStmt: BlockOrLineTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "set-obj-attrib"
    
    public private(set) var SetObject: String = ""
    public private(set) var ObjAttribute: String = ""
    public private(set) var ValueExpression: String = ""
    public private(set) var ModifiersList: [ModifierInstance] = []

    let setVarBlockRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variable
        } transform: { String($0) }
        One(".")
        Capture {
            CommonRegEx.variable
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
        
        CommonRegEx.comments
    }
    
    let setVarLineRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.variable
        } transform: { String($0) }
        One(".")
        Capture {
            CommonRegEx.variable
        } transform: { String($0) }
        OneOrMore(.whitespace)
        
        "="
        
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        
        CommonRegEx.modifiersForExpression_Capturing
        
        CommonRegEx.comments
    }
    
    override func checkIfLineVariant(line: String) -> Bool {
        let match = line.wholeMatch(of: setVarLineRegex )
        return match != nil
    }

    override func matchLine_BlockVariant(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: setVarBlockRegex )
                                                                else { return false }

        let (_, setObj, objAttrib, modifiersList) = match.output
        self.SetObject = setObj
        self.ObjAttribute = objAttrib
        self.ValueExpression = ""
        self.ModifiersList = try Modifiers.parse(string: modifiersList, pInfo: pInfo)
        
        return true
    }
    
    override func matchLine_LineVariant(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: setVarLineRegex )
                                                                else { return false }

        let (_, setObj, objAttrib, value, modifiersList) = match.output
        self.SetObject = setObj
        self.ObjAttribute = objAttrib
        self.ValueExpression = value
        self.ModifiersList = try Modifiers.parse(string: modifiersList, pInfo: pInfo)

        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        if isBlockVariant {
            guard SetObject.isNotEmpty,
                  ObjAttribute.isNotEmpty,
                  children.count != 0 else { return nil }
            
            let variableName = self.SetObject
            let attributeName = self.ObjAttribute
            
            let body = try children.execute(with: ctx)?.trim() ?? ""
            try ctx.setObjProp(objName: variableName, propName: attributeName, body: body, modifiers: ModifiersList, pInfo: pInfo)
            
        } else {
            guard SetObject.isNotEmpty,
                  ObjAttribute.isNotEmpty,
                  ValueExpression.isNotEmpty else { return nil }
            
            let variableName = self.SetObject
            let attributeName = self.ObjAttribute
            
            try ctx.setObjProp(objName: variableName, propName: attributeName, valueExpression: ValueExpression, modifiers: ModifiersList, pInfo: pInfo)
        }
        
        return nil
    }
    
    public var debugDescription: String {
        if self.isBlockVariant {
            var str =  """
            SET OBJ_ATTRIB Block stmt (level: \(pInfo.level))
            - setObj: \(self.SetObject)
            - objAttrib: \(self.ObjAttribute)
            - modifiers: \(self.ModifiersList.nameString())
            - children:
            
            """
            
            str += debugStringForChildren()
            
            return str

        } else { //line variant
            let str =  """
            SET OBJ_ATTRIB Line stmt (level: \(pInfo.level))
            - setObj: \(self.SetObject)
            - objAttrib: \(self.ObjAttribute)
            - valueExpr: \(self.ValueExpression)
            - modifiers: \(self.ModifiersList.nameString())

            """
            
            return str
        }
    }
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static var register = BlockOrLineTemplateStmtConfig(keyword: START_KEYWORD, endKeyword: "endset" ) { endKeyWord, pInfo in
        SetObjectAttributeStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}

