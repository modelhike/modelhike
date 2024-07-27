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
    
    
    override func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt, with ctx: Context) throws -> PartOfMultiBlockContainer? {
        
        let keyWord = blockLime.line.secondWord()
        
        if keyWord == ELSE_KEYWORD {

            let line = blockLime.line.lineWithoutStmtKeyword()
            
            //check for 'Else if" stmt
            if let match = line.wholeMatch(of: elseIfRegex ) {
                let (_, ELSEIFCondition) = match.output
                
                let block = ElseIfBlock(condition: ELSEIFCondition, firstWord: blockLime.line.firstWord()!, line: blockLime.line, lineNo: blockLime.lineNo)
                
                self.elseIfBlocks.append(block)
                return block
            }
        
            //check for 'Else" stmt
            let actualStmt = line.stmtPartOnly()
            let elseMatches = actualStmt == ELSE_KEYWORD
            if elseMatches {
                let block = PartOfMultiBlockContainer(firstWord: ELSE_KEYWORD, line: blockLime.line, lineNo: blockLime.lineNo)
                
                self.elseBlock = block
                return block
            }
            
            //nothing matches the syntax
            throw TemplateSoup_ParsingError.invalidMultiBlockStmt(blockLime.lineNo, blockLime.line)
        }
        
        return nil
    }
    
    override func matchLine(line: String, level: Int, with ctx: Context) throws -> Bool {
        guard let match = line.wholeMatch(of: ifRegex ) else { return false }

        let (_, IFCondition) = match.output
        self.IFCondition = IFCondition
        
        return true
    }
    
    public override func execute(with ctx: Context) throws -> String? {
        guard IFCondition.isNotEmpty,
              children.count != 0 else { return nil }
        
        var rendering = ""
        
        if try ctx.evaluateCondition(expression: IFCondition, lineNo: lineNo) {
            ctx.debugLog.ifConditionSatisfied(IFCondition, lineNo: lineNo)
            
            if let body = try children.execute(with: ctx) {
                rendering += body
            }
        } else if elseIfBlocks.count > 0 { // has Else-If blocks
            for elseIfBlock in elseIfBlocks {
                if try ctx.evaluateCondition(expression: elseIfBlock.condition, lineNo: elseIfBlock.lineNo) {
                    ctx.debugLog.elseIfConditionSatisfied(elseIfBlock.condition, lineNo: elseIfBlock.lineNo)
                    
                    if let body = try elseIfBlock.execute(with: ctx) {
                        rendering += body
                    }
                    break
                }
            }
        } else {
            if let elseBlock = self.elseBlock {
                ctx.debugLog.elseBlockExecuting(elseBlock.line, lineNo: elseBlock.lineNo)
                
                if let body = try elseBlock.execute(with: ctx) {
                    rendering += body
                }
            }
        }
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        var str =  """
        IF stmt (level: \(level))
        - condn: \(self.IFCondition)
        - children:
        
        """
        
        str += debugStringForChildren()
        
        for elseIfBlock in elseIfBlocks {
            if !elseIfBlock.isEmpty {
                str +=  """
                
                ELSE IF stmt (level: \(level))
                - condn: \(elseIfBlock.condition)
                - children:
                
                """
                
                str += elseIfBlock.debugStringForChildren()
            }
        }
        
        if let elseBlock = self.elseBlock {
            str +=  """
            
            ELSE stmt (level: \(level))
            - children:
            
            """
            
            str += elseBlock.debugStringForChildren()
        }
        
        return str
    }
    
    
    public init(parseTill endKeyWord: String) {
        super.init(startKeyword: Self.START_KEYWORD, endKeyword: endKeyWord)
    }
    
    static var register = MultiBlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord in
        IfStmt(parseTill: endKeyWord)
    }
}

public class ElseIfBlock : PartOfMultiBlockContainer {
    
    public var condition = ""
    
    public init(condition: String, firstWord: String, line: String, lineNo: Int) {
        super.init(firstWord: firstWord, line: line, lineNo: lineNo)
        self.condition = condition
    }
}
