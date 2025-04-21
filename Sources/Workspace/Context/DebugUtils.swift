//
//  DebugUtils.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct ContextDebugLog: Sendable {
    public let stack = CallStack()
    public var flags = ContextDebugFlags()
    
    public func parseLines(startingFrom startKeyword : String?, till endKeyWord: String?, line: String?, lineNo : Int ) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            if let startKeyword = startKeyword, let endKeyWord = endKeyWord, let line = line {
                print("[\(lineNo)] PARSE LINES START \"\(startKeyword)\" till>> \(endKeyWord)")
                print(line)
            } else {
                print("PARSE LINES till END-OF-FILE")
            }
        }
    }
    
    public func parseLines(ended endKeyWord: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] PARSE LINES ENDED>> \(endKeyWord)")
        }
    }
    
    public func stmtDetected(keyWord: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)] STMT DETECT>> \(keyWord)")
        }
    }
    
    public func multiBlockDetected(keyWord: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] MULTIBLOCK DETECT>> \(keyWord)")
        }
        
    }
    
    public func multiBlockDetectFailed(pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] FAILED MULTIBLOCK PARSE>> \(pInfo.line) ")
        }
    }
    
    public func comment(line: String, lineNo: Int) {
        print("[\(lineNo)] \(line)")
    }
    
    public func content(_ line: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)] --txt-- \(line)")
        }
    }
    
    public func inlineExpression(_ line: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)] -------{{ \(line) }}")
        }
    }
    
    public func inlineFunctionCall(_ line: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)] -------={{ \(line) }}=")
        }
    }
    
    public func line(_ line: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)]-- \(line)")
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
    
    public func printParsedTree(for containers: SoupyScriptStmtContainerList) async {
        if flags.printParsedTree {
            await print(containers.debugDescription)
        }
    }
    
    public func ifConditionSatisfied(condition: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] IF Condition Satisfied>> \(pInfo.line)")
        }
    }
    
    public func elseIfConditionSatisfied(condition: String, pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] ELSE IF Condition Satisfied>> \(pInfo.line)")
        }
    }
    
    public func elseBlockExecuting(_ pInfo: ParsedInfo) {
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] ELSE Block executing>> \(pInfo.line)")
        }
    }
    
    public func templateParsingStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("TEMPLATE PARSING START -------------\n\n")
        }
    }
    
    public func templateExecutionStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("\n\n\n\nTEMPLATE EXECTION START -------------\n")
        }
    }
    
    public func scriptFileParsingStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("SCRIPT PARSING START -------------\n\n")
        }
    }
    
    public func scriptFileExecutionStarting() {
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("\n\n\n\nSCRIPT TEMPLATE EXECTION START -------------\n")
        }
    }
    
    public func workingDirectoryChanged(_ path: String) {
        if flags.changesInWorkingDirectory {
            print("Working Dir: \(path)")
        }
    }
    
    public func excludingFile(_ filepath: String) {
        if flags.excludedFiles {
            print("⚠️ Excluding \(filepath) ...")
        }
    }
    
    public func stopRenderingCurrentFile(_ filepath: String, pInfo: ParsedInfo) {
        if flags.renderingStoppedInFiles {
            print("⚠️ Stop Rendering \(filepath) ...")
        }
    }
    
    public func throwErrorFromCurrentFile(_ filepath: String, err: String, pInfo: ParsedInfo) {
        if flags.errorThrownInFiles {
            print("🚨 Error '\(err)' Thrown From \(filepath) ...")
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
    
    public func copyingFileInFolder(_ filepath: String, folder: LocalFolder) {
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Copying \(filepath) ...")
        }
    }
    
    public func copyingFileInFolder(_ filepath: String, to newFilePath: String, folder: LocalFolder) {
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Copying \(filepath) to \(newFilePath)...")
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
    
    public func renderingFolder(_ path: String, to newPath: String) {
        if flags.fileGeneration {
            print("Rendering folder \(path) to \(newPath)...")
        }
    }
    
    public func generatingFile(_ filepath: String, with template: String) {
        if flags.fileGeneration {
            print("Generating \(filepath) [template \(template)] ...")
        }
    }
    
    public func fileNotGenerated(_ filepath: String, with template: String) {
        if flags.fileGeneration {
            print("⚠️ File \(filepath) [template \(template)] not Generated!!!...")
        }
    }
    
    public func generatingFileInFolder(_ filepath: String, with template: String, folder: LocalFolder) {
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Generating \(filepath) [template \(template)] ...")
        }
    }
    
    public func fileNotGeneratedInFolder(_ filepath: String, with template: String, folder: LocalFolder) {
        if flags.fileGeneration {
            print("⚠️ [ \(folder.pathString) ]  File \(filepath) [template \(template)] not Generated!!!...")
        }
    }
    
    public func fileNotGenerated(_ filepath: String) {
        if flags.fileGeneration {
            print("⚠️ File \(filepath) not Generated!!!...")
        }
    }
    
    public func pipelinePhaseCannotRun(_ phase: any PipelinePhase, msg: String) {
        print("⦻ Phase \(phase) cannot run!!!...")
        print("⦻ \(msg)!!!...")
    }
    
    public func pipelinePassCannotRun(_ pass: any PipelinePass, msg: String? = nil) {
        print("⦻ Pass \(pass) cannot run!!!...")
        if let msg {
            print("⦻ \(msg)!!!...")
        }
    }
    
    public init(flags: ContextDebugFlags) {
        self.flags = flags
    }
}

public struct ContextDebugFlags: Sendable {
    public var printParsedTree = false
    
    public var lineByLineParsing = false
    public var blockByBlockParsing = false
    public var controlFlow = false
    
    public var excludedFiles = false
    public var renderingStoppedInFiles = false
    public var errorThrownInFiles = false
    
    public var changesInWorkingDirectory = false
    public var fileGeneration = false
    
    public var onSkipLines = false
    public var onIncrementLines = false
    public var onCommentedLines = false
    
    public init() {}
}
