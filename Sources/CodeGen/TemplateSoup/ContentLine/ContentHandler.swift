//
//  ContentHandler.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

public enum ContentHandler {
    
    nonisolated(unsafe)
    static let lineRegEx: Regex<(Substring, String, Optional<String>, Optional<String>)>  = Regex {
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
    
    nonisolated(unsafe)
    static let inlineFnCallRegEx: Regex<(Substring, Optional<String>)> = Regex {
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
    
    nonisolated(unsafe)
    static let printExpressionRegEx: Regex<(Substring, Optional<String>)> = Regex {
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
    
    
    static func parseLine(_ line: String, pInfo: ParsedInfo, level: Int) async throws -> [ContentLineItem] {
        let ctx = pInfo.ctx
        
        var items: [ContentLineItem] = []

        await ctx.debugLog.content(line, pInfo: pInfo)
        
        let matches = line.matches(of: Self.lineRegEx )
            
        for match in matches {
            let (_, text, inlineCall, expression) = match.output
            
            //print(text, inlineCall, expression)
            
            if text.count > 0 {
                let textContent = TextContent(text, pInfo: pInfo, level: level)
                items.append(textContent)
            }
            
            if let inlineCall = inlineCall {
                await ctx.debugLog.inlineFunctionCall(inlineCall, pInfo: pInfo)
                
                let inlineCallContent = try InlineFunctionCallContent(fnCallLine: inlineCall, pInfo: pInfo, level: level)
                items.append(inlineCallContent)
            }
            
            if let expression = expression {
                await ctx.debugLog.inlineExpression(expression, pInfo: pInfo)
                
                let expressionContent = try await PrintExpressionContent(expressionLine: expression, pInfo: pInfo, level: level)
                items.append(expressionContent)
            }
        }
        
        return items
    }
    
    public static func execute(line: String, identifier: String, with ctx: Context) async throws -> String? {
        var str = ""
        
        let pInfo = await ParsedInfo.dummy(line: line, identifier: identifier, with: ctx);
        let items = try await parseLine(line, pInfo: pInfo, level: 0)
        
        for item in items {
            if let result = try await item.execute(with: ctx) {
                str += result
            }
        }
        
        return str.trim().isNotEmpty ? str : nil
    }
    
    public static func eval(line: String, pInfo: ParsedInfo) async throws -> String? {
        return try await ContentHandler.execute(line: line, identifier: pInfo.identifier, with: pInfo.ctx)
    }
    
    public static func eval(expression: String, pInfo: ParsedInfo) async throws -> String? {
        return try await ContentHandler.execute(line: expression, identifier: pInfo.identifier, with: pInfo.ctx)
    }
    
    public static func eval(expression: String, with ctx: GenerationContext) async throws -> String? {
        return try await ContentHandler.execute(line: expression, identifier: "Eval", with: ctx)
    }
}
