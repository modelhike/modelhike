//
// DebugUtils.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct ContextDebugLog {
    public var flags = ContextDebugFlags()

    public func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, line: String?, lineNo: Int ) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            if let startKeyword = startKeyword, let endKeyWord = endKeyWord, let line = line {
                print("[\(lineNo)] PARSE LINES START \"\(startKeyword)\" till>> \(endKeyWord)")
                print(line)
            } else {
                print("PARSE LINES till END-OF-FILE")
            }
        }
    }
    
    public func parseLines(ended endKeyWord: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(lineNo)] PARSE LINES ENDED>> \(endKeyWord)")
        }
    }
    
    public func stmtDetected(keyWord: String, lineNo: Int) {
        if flags.lineByLineParsing {
            print("[\(lineNo)] STMT DETECT>> \(keyWord)")
        }
    }
    
    public func multiBlockDetected(keyWord: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(lineNo)] MULTIBLOCK DETECT>> \(keyWord)")
        }
        
    }
    
    public func multiBlockDetectFailed(line: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(lineNo)] FAILED MULTIBLOCK PARSE>> \(line) ")
        }
    }
    
    public func comment(line: String, lineNo: Int) {
        print("[\(lineNo)] \(line)")
    }
    
    public func content(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing {
            print("[\(lineNo)] --txt-- \(line)")
        }
    }
    
    public func inlineExpression(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing {
            print("[\(lineNo)] -------{{ \(line) }}")
        }
    }
    
    public func inlineFunctionCall(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing {
            print("[\(lineNo)] -------={{ \(line) }}=")
        }
    }
    
    public func line(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing {
            print("[\(lineNo)]-- \(line)")
        }
    }
    
    public func skipEmptyLine(lineNo: Int) {
        if flags.onSkipLines {
            print("[\(lineNo)] skipping empty line...")
        }
    }
    
    public func skipLine(lineNo: Int) {
        if flags.onSkipLines {
            print("[\(lineNo)] skipping line...")
        }
    }
    
    public func skipLine(by times : Int, lineNo: Int) {
        if flags.onSkipLines {
            for i in 0..<times {
                print("[\(lineNo + i)] skipping line...")
            }
        }
    }
    
    public func incrementLineNo(lineNo: Int) {
        if flags.onIncrementLines {
            print("[\(lineNo)] next line...")
        }
    }
    
    public func printParsedTree(for containers: TemplateStmtContainerList) {
        if flags.printParsedTree {
            print(containers.debugDescription)
        }
    }
    
    public func ifConditionSatisfied(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(lineNo)] IF Condition Satisfied>> \(line)")
        }
    }
    
    public func elseIfConditionSatisfied(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(lineNo)] ELSE IF Condition Satisfied>> \(line)")
        }
    }
    
    public func elseBlockExecuting(_ line: String, lineNo: Int) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(lineNo)] ELSE Block executing>> \(line)")
        }
    }
    
    public func templateParsingStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("PARSING START -------------\n\n")
        }
    }
    
    public func templateExecutionStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("\n\n\n\nEXECTION START -------------\n")
        }
    }
    
    public func workingDirectoryChanged(_ path: String) {
        if flags.changesInWorkingDirectory {
            print("Working Dir: \(path)")
        }
    }
    
    public func generatingFile(_ filepath: String) {
        if flags.fileGeneration {
            print("Generating \(filepath) ...")
        }
    }
    
    public func copyingFile(_ filepath: String) {
        if flags.fileGeneration {
            print("Copying \(filepath) ...")
        }
    }
    
    public func copyingFile(_ filepath: String, to newFilePath: String) {
        if flags.fileGeneration {
            print("Copying \(filepath) to \(newFilePath)...")
        }
    }
    
    public func copyingFolder(_ path: String) {
        if flags.fileGeneration {
            print("Copying folder \(path) ...")
        }
    }
    
    public func copyingFolder(_ path: String, to newPath: String) {
        if flags.fileGeneration {
            print("Copying folder \(path) to \(newPath)...")
        }
    }
    
    public func generatingFile(_ filepath: String, with template: String) {
        if flags.fileGeneration {
            print("Generating \(filepath) [template \(template)] ...")
        }
    }
}

public struct ContextDebugFlags {
    public var printParsedTree = false
    
    public var lineByLineParsing = false
    public var blockByBlockParsing = false
    public var controlFlow = false

    public var changesInWorkingDirectory = false
    public var fileGeneration = false

    public var onSkipLines = false
    public var onIncrementLines = false
    public var onCommentedLines = false
}
