//
// IfStmt.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class IfStmt: MultiBlockTemplateStmt, CustomDebugStringConvertible {
    static let START_KEYWORD = "if"

    public private(set) var IFCondition: String = ""
    public private(set) var elseIfBlocks : [ElseIfBlock] = []
    public private(set) var elseBlock : PartOfMultiBlockContainer? = nil

    let ELSE_KEYWORD = "else"
    
    let ifRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    let elseIfRegex = Regex {
        "else if"
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    
    override func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt) throws -> PartOfMultiBlockContainer? {
        
        let keyWord = blockLime.line.secondWord()
        
        if keyWord == ELSE_KEYWORD {

            let line = blockLime.line.lineWithoutStmtKeyword()
            
            //check for 'Else if" stmt
            if let match = line.wholeMatch(of: elseIfRegex ) {
                let (_, ELSEIFCondition) = match.output
                
                let block = ElseIfBlock(condition: ELSEIFCondition, pInfo: blockLime.pInfo)
                
                self.elseIfBlocks.append(block)
                return block
            }
        
            //check for 'Else" stmt
            let actualStmt = line.stmtPartOnly()
            let elseMatches = actualStmt == ELSE_KEYWORD
            if elseMatches {
                let block = PartOfMultiBlockContainer(firstWord: ELSE_KEYWORD, pInfo: blockLime.pInfo)
                
                self.elseBlock = block
                return block
            }
            
            //nothing matches the syntax
            throw TemplateSoup_ParsingError.invalidMultiBlockStmt(blockLime.lineNo, blockLime.line)
        }
        
        return nil
    }
    
    override func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: ifRegex ) else { return false }

        let (_, IFCondition) = match.output
        self.IFCondition = IFCondition
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard IFCondition.isNotEmpty,
              children.count != 0 else { return nil }
        
        var rendering = ""
        
        if try ctx.evaluateCondition(expression: IFCondition, pInfo: pInfo) {
            ctx.debugLog.ifConditionSatisfied(condition: IFCondition, pInfo: self.pInfo)
            
            if let body = try children.execute(with: ctx) {
                rendering += body
            }
        } else {
            var conditionEvalIsTrue = false
            
            for elseIfBlock in elseIfBlocks {
                if try ctx.evaluateCondition(expression: elseIfBlock.condition, pInfo: elseIfBlock.pInfo) {
                    ctx.debugLog.elseIfConditionSatisfied(condition: elseIfBlock.condition, pInfo: elseIfBlock.pInfo)
                    
                    conditionEvalIsTrue = true

                    if let body = try elseIfBlock.execute(with: ctx) {
                        rendering += body
                    }
                    break
                }
            }

            //if no condition is evaluating to true
            if let elseBlock = self.elseBlock, !conditionEvalIsTrue {
                ctx.debugLog.elseBlockExecuting(elseBlock.pInfo)
                
                if let body = try elseBlock.execute(with: ctx) {
                    rendering += body
                }
            }
        }
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        var str =  """
        IF stmt (level: \(pInfo.level))
        - condn: \(self.IFCondition)
        - children:
        
        """
        
        str += debugStringForChildren()
        
        for elseIfBlock in elseIfBlocks {
            if !elseIfBlock.isEmpty {
                str +=  """
                
                ELSE IF stmt (level: \(pInfo.level))
                - condn: \(elseIfBlock.condition)
                - children:
                
                """
                
                str += elseIfBlock.debugStringForChildren()
            }
        }
        
        if let elseBlock = self.elseBlock {
            str +=  """
            
            ELSE stmt (level: \(pInfo.level))
            - children:
            
            """
            
            str += elseBlock.debugStringForChildren()
        }
        
        return str
    }
    
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static var register = MultiBlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in
        IfStmt(parseTill: endKeyWord, pInfo: pInfo)
    }
}

public class ElseIfBlock : PartOfMultiBlockContainer {
    
    public var condition = ""
    
    public init(condition: String, pInfo: ParsedInfo) {
        super.init(firstWord: pInfo.firstWord, pInfo: pInfo)
        self.condition = condition
    }
}
