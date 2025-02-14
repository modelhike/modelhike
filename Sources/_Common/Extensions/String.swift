//
// String.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public extension String {
    var isNotEmpty: Bool { !isEmpty }

    static var empty: String { "" }
    
    func isOnly(_ txt: String) -> Bool {
        return self.trim() == txt
    }
    
    func hasOnly(_ txt: String) -> Bool {
        let trimmed = self.trim()
        if (trimmed.isEmpty) { return false }
            
        let selfCount = trimmed.count
        let comparedString = String(repeating: String(txt), count: selfCount)
        return trimmed == comparedString
    }
    
    func hasOnly(_ times: Int, of txt: String) -> Bool {
        let trimmed = self.trim()
        if (trimmed.isEmpty) { return false }

        let comparedString = String(repeating: String(txt), count: times)
        return trimmed == comparedString
    }
    
    func has(prefix: String, filler txt: String, suffix: String) -> Bool {
        if self.hasPrefix(prefix) && self.hasSuffix(suffix) {
            if let filler = between(prefix: prefix, suffix: suffix),
                filler.hasOnly(ModelConstants.NameOverlineChar) {
                return true
            }
        }
        
        return false
    }
    
    func firstWord() -> String? {
        let arr = self.components(separatedBy: .whitespaces)
                
        for item in arr {
            if item.trim().isNotEmpty {
                return item //first non empty item
            }
        }
        
        return nil
    }
    
    func secondWord() -> String? {
        let arr = self.components(separatedBy: .whitespaces)
        
        let nonEmptyArray = arr.filter({ $0.trim().isNotEmpty })
                
        if nonEmptyArray.count > 1 {
            return nonEmptyArray[1] //second item
        } else {
            return nil
        }
    }
    
    func firstAndsecondWord() -> (String?, String?) {
        let arr = self.components(separatedBy: .whitespaces)
        
        let nonEmptyArray = arr.filter({ $0.trim().isNotEmpty })
                
        if nonEmptyArray.count > 1 {
            return (nonEmptyArray[0], nonEmptyArray[1])
        } else if nonEmptyArray.count > 0 {
            return (nonEmptyArray[0], nil)
        }else {
            return (nil, nil)
        }
    }
    
    func lastWord() -> String? {
        let arr = self.components(separatedBy: .whitespaces)
        
        let nonEmptyArray = arr.filter({ $0.trim().isNotEmpty })
        return nonEmptyArray.last
    }
    
    func dropFirstWord() -> String {
        if let firstWord = firstWord() {
            return remainingLine(after: firstWord)
        } else {
            return self
        }
    }
    
    func dropLastWord() -> String {
        let strWithoutLastWord = self.components(separatedBy: .whitespaces).dropLast()
                                     .joined(separator: " ")
        return strWithoutLastWord
    }
    
    func dropFirstAndLastWords() -> String {
        let firstWordDropped = dropFirstWord()
        return firstWordDropped.dropLastWord()
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func trimTrailing() -> String {
        let characterSet: CharacterSet = .whitespacesAndNewlines
        
        guard let index = lastIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
            return self
        }

        return String(self[...index])
    }
    
    func stmtPartOnly() -> String {
        return remainingLine(after: TemplateConstants.stmtKeyWord).trim()
    }
    
    func lineWithoutStmtKeyword() -> String {
        return remainingLine(after: TemplateConstants.stmtKeyWord)
    }
    
    func remainingLine(after word: String) -> String {
        let currentLine = self
        
        if let range = currentLine.range(of: word) {
            let remainingLine =  String(currentLine[range.upperBound...])
            return remainingLine.trim()
        } else {
            return currentLine.trim()
        }
    }
    
    func between(prefix: String, suffix: String) -> String? {
        guard let prefixRange = self.range(of: prefix) else { return nil }
        
        let startIndex = prefixRange.upperBound
        guard let suffixRange = self[startIndex...].range(of: suffix) else { return nil }
        
        let endIndex = suffixRange.lowerBound
        return String(self[startIndex..<endIndex])
    }
    
    var isStartingWithAlphabet : Bool {
        return first?.isAsciiLetter == true
    }
    
    func slugify() -> String {
        return self.lowercased().normalizeForFolderName().camelCaseToSnakeCase()
    }
    
    func normalizeForVariableName() -> String {
        let _functionNamePattern = "[^A-Za-z_0-9]+"

        var code  = self
        //code = code.replacingOccurrences(of: "-", with: "")
        code = code.replacingOccurrences(of: " ", with: "")
        code = code.replacingOccurrences(of: _functionNamePattern, with: "_", options: [.regularExpression])

        if  let first = code.first, first.isNumber {
            code = "value" + code
        }
        
//        //make all lower case to upper case names, so as not to clash with js keywords which are all lowercase
//        if  let first = code.first, first.isLowercase {
//            let dropped = code.dropFirst()
//            code = first.uppercased() + String(dropped)
//        }
        
        return code
    }
    
    func normalizeForPackageName() -> String {
        let _functionNamePattern = "[^A-Za-z_.0-9]+"
        
        var code  = self
        //code = code.replacingOccurrences(of: "-", with: "")
        code = code.replacingOccurrences(of: " ", with: ".")
        code = code.replacingOccurrences(of: _functionNamePattern, with: "_", options: [.regularExpression])
        
        if  let first = code.first, first.isNumber {
            code = "value" + code
        }
        
        //        //make all lower case to upper case names, so as not to clash with js keywords which are all lowercase
        //        if  let first = code.first, first.isLowercase {
        //            let dropped = code.dropFirst()
        //            code = first.uppercased() + String(dropped)
        //        }
        
        return code
    }
    
    func normalizeForId() -> String {
        let _functionNamePattern = "[^A-Za-z_0-9]+"

        var code  = self
        code = code.replacingOccurrences(of: "-", with: "")
        code = code.replacingOccurrences(of: _functionNamePattern, with: "", options: [.regularExpression])
        
        return code
    }
    
    func normalizeForFolderName() -> String {
        let _functionNamePattern = "[^A-Za-z0-9]+"

        var code  = self
        code = code.replacingOccurrences(of: _functionNamePattern, with: "-", options: [.regularExpression])
        
        return code
    }
    
    func pluralized(count: Int = 2) -> String {
        guard (count > 1) else {
            return self
        }
    
        return PluralKit.shared.apply(word: self)
    }
    
    func hasDot() -> Bool {
        if let _ = self.firstIndex(of: ".") {
            return true
        } else {
            return false
        }
    }
    
    func uppercasedFirst() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self[self.index(self.startIndex, offsetBy: 1)...]
    }
    func withoutFileExtension() -> String {
        let url = URL(string: self)
        let filename = url?.deletingPathExtension().lastPathComponent
        return filename ?? self
    }
    
    func fileExtension() -> String {
        let url = URL(string: self)
        let ext = url?.pathExtension
        return ext ?? self
    }
    
    //removes all spaces in the string
    //for selective spaces, replace 🔥 symbol with a single space
    func spaceless() -> String {
        let withoutSpace = self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined()
        return withoutSpace.replacingOccurrences(of: "🔥", with: " ")
    }
    
    static var newLine = "\n"
    static var newLine2 = "\r\n"

    func splitIntoLines() -> [String] {
        //return self.components(separatedBy: .newlines)
        return split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
    }
}

public extension Array where Element == String {
    func trim() -> [String] {
        var arr : [String] = []
        for str in self {
            arr.append(str.trim())
        }
        return arr
    }
}

public extension Substring {
    var isNotEmpty: Bool { !isEmpty }

    func firstWord() -> String? {
        return self.components(separatedBy: .whitespaces).first
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension Array where Element == Substring {
    func trim() -> [String] {
        var arr : [String] = []
        for str in self {
            arr.append(str.trim())
        }
        return arr
    }
}

//SRC: https://gist.github.com/dmsl1805/ad9a14b127d0409cf9621dc13d237457
public extension String {
  func camelCaseToSnakeCase() -> String {
    let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
    let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
    let digitsFirstPattern = "([0-9])([A-Z])"
    return self.processCamelCaseRegex(pattern: acronymPattern)?
      .processCamelCaseRegex(pattern: fullWordsPattern)?
      .processCamelCaseRegex(pattern:digitsFirstPattern)?.lowercased() ?? self.lowercased()
  }

  fileprivate func processCamelCaseRegex(pattern: String) -> String? {
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: count)
    return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
  }
    
    func camelCaseToKebabCase() -> String {
      let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
      let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
      let digitsFirstPattern = "([0-9])([A-Z])"
      return self.processKebabCaseRegex(pattern: acronymPattern)?
        .processKebabCaseRegex(pattern: fullWordsPattern)?
        .processKebabCaseRegex(pattern:digitsFirstPattern)?.lowercased() ?? self.lowercased()
    }

    fileprivate func processKebabCaseRegex(pattern: String) -> String? {
      let regex = try? NSRegularExpression(pattern: pattern, options: [])
      let range = NSRange(location: 0, length: count)
      return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1-$2")
    }
}

extension Character {
    var isAsciiLetter: Bool { "A"..."Z" ~= self || "a"..."z" ~= self }
}
