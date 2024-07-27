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
        let selfCount = trimmed.count
        let comparedString = String(repeating: String(txt), count: selfCount)
        return trimmed == comparedString
    }
    
    func firstWord() -> String? {
        let arr = self.components(separatedBy: " ")
                
        for item in arr {
            if item.trim().isNotEmpty {
                return item //first non empty item
            }
        }
        
        return nil
    }
    
    func secondWord() -> String? {
        let arr = self.components(separatedBy: " ")
        
        var nonEmptyArray : [String] = []
        
        for item in arr {
            if item.trim().isNotEmpty {
                nonEmptyArray.append(item)
            }
        }
                
        if nonEmptyArray.count > 1 {
            return nonEmptyArray[1] //second item
        } else {
            return nil
        }
    }
    
    func firstAndsecondWord() -> (String?, String?) {
        let arr = self.components(separatedBy: " ")
        
        var nonEmptyArray : [String] = []
        
        for item in arr {
            if item.trim().isNotEmpty {
                nonEmptyArray.append(item)
            }
        }
                
        if nonEmptyArray.count > 1 {
            return (nonEmptyArray[0], nonEmptyArray[1])
        } else if nonEmptyArray.count > 0 {
            return (nonEmptyArray[0], nil)
        }else {
            return (nil, nil)
        }
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
    
    func moduleName() -> String {
        return self.lowercased().normalizeForFolderName().camelCaseToSnakeCase()
    }
    
    func normalizeForVariableName() -> String {
        let _functionNamePattern = "[^A-Za-z_0-9]+"

        var code  = self
        code = code.replacingOccurrences(of: "-", with: "")
        code = code.replacingOccurrences(of: _functionNamePattern, with: "_", options: [.regularExpression])

        if  let first = code.first, first.isNumber {
            code = "value" + code
        }
        
        //make all lower case to upper case names, so as not to clash with js keywords which are all lowercase
        if  let first = code.first, first.isLowercase {
            let dropped = code.dropFirst()
            code = first.uppercased() + String(dropped)
        }
        
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
    
    //removes all spaces in the string
    func spaceless() -> String {
        return self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined()
    }
    
    static var newLine = "\n"
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
        return self.components(separatedBy: " ").first
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
