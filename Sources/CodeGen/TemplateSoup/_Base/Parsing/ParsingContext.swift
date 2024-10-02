//
// ParsingContext.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public class ParsingContext {
    public internal(set) var line: String
    public internal(set) var firstWord: String
    public internal(set) var parser: LineParser

    public init?(parser: LineParser) {
        self.line = parser.currentLine()
        
        guard let firstWord = line.firstWord() else { return nil }
        self.firstWord = firstWord
        self.parser = parser
    }
}
