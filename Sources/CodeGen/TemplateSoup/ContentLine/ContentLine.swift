//
// ContentLine.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation
import RegexBuilder

public class ContentLine: FileTemplateItem, CustomDebugStringConvertible {
    public var items: [ContentLineItem] = []
    public let level: Int
    public let lineNo: Int
    let ctx: Context
    
    static let lineRegEx = Regex {
        Capture {
            ZeroOrMore {
                NegativeLookahead {
                    "={{"
                }
                NegativeLookahead {
                    "{{"
                }
                CharacterClass.any
            }
        } transform: { String($0) }
        
        inlineFnCallRegEx
        
        printExpressionRegEx
    }
    
    static let inlineFnCallRegEx: Regex<Regex<Optionally<(Substring, String?)>.RegexOutput>.RegexOutput> = Regex {
        Optionally {
            "={{"
            Capture {
                ZeroOrMore {
                    NegativeLookahead {
                        "}}="
                    }
                    CharacterClass.any
                }
            } transform: { String($0) }
            "}}="
        }
    }
    
    static let printExpressionRegEx: Regex<Regex<Optionally<(Substring, String?)>.RegexOutput>.RegexOutput> = Regex {
        Optionally {
            "{{"
            Capture {
                ZeroOrMore {
                    NegativeLookahead {
                        "}}"
                    }
                    CharacterClass.any
                }
            } transform: { String($0) }
            "}}"
        }
    }
    
    
    fileprivate func parseLine(_ line: String) throws {
        ctx.debugLog.content(line, lineNo: lineNo)
        
        let matches = line.matches(of: Self.lineRegEx )
            
        for match in matches {
            let (_, text, inlineCall, expression) = match.output
            
            //print(text, inlineCall, expression)
            
            if text.count > 0 {
                let textContent = TextContent(text, lineNo: lineNo, level: level)
                self.items.append(textContent)
            }
            
            if let inlineCall = inlineCall {
                ctx.debugLog.inlineFunctionCall(inlineCall, lineNo: lineNo)
                
                let inlineCallContent = try InlineFunctionCallContent(fnCallLine: inlineCall, lineNo: lineNo, level: level, with: ctx)
                self.items.append(inlineCallContent)
            }
            
            if let expression = expression {
                ctx.debugLog.inlineExpression(expression, lineNo: lineNo)
                
                let expressionContent = try PrintExpressionContent(expressionLine: expression, lineNo: lineNo, level: level, with: ctx)
                self.items.append(expressionContent)
            }
        }
    }
    
    public func execute(with ctx: Context) throws -> String? {
        var str = ""
        
        for item in items {
            if let result = try item.execute(with: ctx) {
                str += result
            }
        }
        
        return str.trim().isNotEmpty ? str + .newLine : nil
    }
    
    public var debugDescription: String { 
        var str = ""
        
        for item in items {
            str += item.debugDescription + .newLine
        }
        
        return str
    }
    
    
    public init(_ content: String, lineNo: Int, level: Int, with ctx: Context) throws {
        self.lineNo = lineNo
        self.level = level
        self.ctx = ctx
        
        try self.parseLine(content)
    }
}

public protocol ContentLineItem : CustomDebugStringConvertible{
    func execute(with ctx: Context) throws -> String?
}
