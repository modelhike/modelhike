//
//  IfStmt.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public struct IfStmt: MultiBlockTemplateStmt, CustomDebugStringConvertible {
    public var state: MutipleBlockTemplateStmtState
    
    static let START_KEYWORD = "if"
    static let ELSE_IF_KEYWORD = "else-if"
    static let ELSE_KEYWORD = "else"

    public private(set) var IFCondition: String = ""
    public private(set) var elseIfBlocks : [ElseIfBlock] = []
    public private(set) var elseBlock : PartOfMultiBlockContainer? = nil

    nonisolated(unsafe)
    let ifRegex = Regex {
        START_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    nonisolated(unsafe)
    let elseIfRegex = Regex {
        ELSE_IF_KEYWORD
        OneOrMore(.whitespace)
        Capture {
            CommonRegEx.anything
        } transform: { String($0) }
        ZeroOrMore(.whitespace)
        
        CommonRegEx.comments
    }
    
    
    mutating func checkIfSupportedAndGetBlock(blockLime: UnIdentifiedStmt) async throws -> PartOfMultiBlockContainer? {
        
        var keyWord = ""
        
         if await blockLime.pInfo.parser.isStatementsPrefixedWithKeyword {
            keyWord =  blockLime.pInfo.secondWord ?? ""
        } else {
            keyWord =  blockLime.pInfo.firstWord
        }

        let line = blockLime.pInfo.line.lineWithoutStmtKeyword()

        if keyWord == Self.ELSE_IF_KEYWORD {
            
            //check for 'Else if" stmt
            if let match = line.wholeMatch(of: elseIfRegex ) {
                let (_, ELSEIFCondition) = match.output
                
                let block = ElseIfBlock(condition: ELSEIFCondition, pInfo: blockLime.pInfo)
                
                self.elseIfBlocks.append(block)
                return block
            }
        }
        else if keyWord == Self.ELSE_KEYWORD {
            
            //check for 'Else" stmt
            let actualStmt = line.stmtPartOnly()
            let elseMatches = actualStmt == Self.ELSE_KEYWORD
            if elseMatches {
                let block = PartOfMultiBlockContainer(firstWord: Self.ELSE_KEYWORD, pInfo: blockLime.pInfo)
                
                self.elseBlock = block
                return block
            }
        } else {
            //nothing matches the syntax
            throw TemplateSoup_ParsingError.invalidMultiBlockStmt(blockLime.pInfo)
        }
            
        return nil
    }
    
    public mutating func matchLine(line: String) throws -> Bool {
        guard let match = line.wholeMatch(of: ifRegex ) else { return false }

        let (_, IFCondition) = match.output
        self.IFCondition = IFCondition
        
        return true
    }
    
    public func execute(with ctx: Context) async throws -> String? {
        guard IFCondition.isNotEmpty else { return nil }
        
        var rendering = ""
        
        if try await ctx.evaluateCondition(expression: IFCondition, with: pInfo) {
            await ctx.debugLog.ifConditionSatisfied(condition: IFCondition, pInfo: self.pInfo)
            
            if let body = try await children.execute(with: ctx) {
                rendering += body
            }
        } else {
            var conditionEvalIsTrue = false
            
            for elseIfBlock in elseIfBlocks {
                if try await ctx.evaluateCondition(expression: elseIfBlock.condition, with: elseIfBlock.pInfo) {
                    await ctx.debugLog.elseIfConditionSatisfied(condition: elseIfBlock.condition, pInfo: elseIfBlock.pInfo)
                    
                    conditionEvalIsTrue = true

                    if let body = try elseIfBlock.execute(with: ctx) {
                        rendering += body
                    }
                    break
                }
            }

            //if no condition is evaluating to true
            if let elseBlock = self.elseBlock, !conditionEvalIsTrue {
                await ctx.debugLog.elseBlockExecuting(elseBlock.pInfo)
                
                if let body = try elseBlock.execute(with: ctx) {
                    rendering += body
                }
            }
        }
        
        return rendering.isNotEmpty ? rendering : nil
    }
    
    public var debugDescription: String {
        get async {
            var str =  """
        IF stmt (level: \(pInfo.level))
        - condn: \(self.IFCondition)
        - children:
        
        """
            
            await str += debugStringForChildren()
            
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
    }
    
    
    public init(parseTill endKeyWord: String, pInfo: ParsedInfo) {
        state = MutipleBlockTemplateStmtState(keyword: Self.START_KEYWORD, endKeyword: endKeyWord, pInfo: pInfo)
    }
    
    static let register = MultiBlockTemplateStmtConfig(keyword: START_KEYWORD) { endKeyWord, pInfo in
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
