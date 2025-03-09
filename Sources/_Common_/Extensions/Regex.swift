//
//  RegEx.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation
import RegexBuilder

//src: https://stackoverflow.com/a/73916264
//extension to allow choiceOf from an array
public extension ChoiceOf where RegexOutput == Substring {
    init<S: Sequence<String>>(_ components: S) {
        let exps = components.map { AlternationBuilder.buildExpression($0) }
        
        guard !exps.isEmpty else {
            fatalError("Empty choice!")
        }
        
        self = exps.dropFirst().reduce(AlternationBuilder.buildPartialBlock(first: exps[0])) { acc, next in
            AlternationBuilder.buildPartialBlock(accumulated: acc, next: next)
        }
    }
}

public extension String {
    func isPattern<T>(_ pattern: Regex<T>) -> Bool {
        if let _ = self.wholeMatch(of: pattern) {
            return true
        } else {
            return false
        }
    }
    
    func getArray_UsingUnNamedArgsPattern() -> [String] {
        let matches = self.matches(of: CommonRegEx.unNamedArguments_Capturing)
        
        let args = matches.map( { match in
            let (_, argument) = match.output
            return argument
        })
        
        return args
    }
    
    func getArray_UsingNamedArgsPattern() -> [ArgumentDeclaration] {
        let matches = self.matches(of: CommonRegEx.namedArguments_Capturing)
        
        let args = matches.map( { match in
            let (_, name, value) = match.output
            return ArgumentDeclaration(name: name, value: value)
        })
        
        return args
    }
}

public struct ArgumentDeclaration {
    let name: String
    let value: String
}
