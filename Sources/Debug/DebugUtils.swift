//
//  DebugUtils.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

private func sourceLocation(from pInfo: ParsedInfo) -> SourceLocation {
    SourceLocation(fileIdentifier: pInfo.identifier, lineNo: pInfo.lineNo, lineContent: pInfo.line, level: pInfo.level)
}

public final class ContextDebugLog: Sendable {
    public let stack = CallStack()
    public let flags: ContextDebugFlags
    private let recorder: (any DebugRecorder)?

    public init(flags: ContextDebugFlags, recorder: (any DebugRecorder)? = nil) {
        self.flags = flags
        self.recorder = recorder
    }

    private func recordEvent(_ event: DebugEvent) {
        guard let recorder else { return }
        Task { await recorder.recordEvent(event) }
    }

    /// Records file generation and adds to session.files for traceability.
    public func recordFileGenerated(outputPath: String, templateName: String?, objectName: String?, workingDir: String, source: SourceLocation) async {
        guard let recorder else {
            recordEvent(.fileGenerated(outputPath: outputPath, templateName: templateName, objectName: objectName, source: source))
            return
        }
        await recorder.recordGeneratedFile(
            outputPath: outputPath,
            templateName: templateName,
            objectName: objectName,
            workingDir: workingDir,
            source: source
        )
    }

    /// Capture current variables as base snapshot for time-travel. Pass variables from context.
    public func captureVariablesForDebug(_ variables: [String: Sendable]) {
        guard let recorder else { return }
        let serialized: [String: String] = variables.mapValues { v in
            if let s = v as? String { return s }
            if let n = v as? Int { return String(n) }
            if let b = v as? Bool { return String(b) }
            if let d = v as? Double { return String(d) }
            return String(describing: v)
        }
        Task { await recorder.captureBaseSnapshot(label: "file-gen", variables: serialized) }
    }

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
        recordEvent(.parseBlockEnded(keyword: endKeyWord, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] PARSE LINES ENDED>> \(endKeyWord)")
        }
    }
    
    public func stmtDetected(keyWord: String, pInfo: ParsedInfo) {
        recordEvent(.statementDetected(keyword: keyWord, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing {
            print("[\(pInfo.lineNo)] STMT DETECT>> \(keyWord)")
        }
    }
    
    public func multiBlockDetected(keyWord: String, pInfo: ParsedInfo) {
        recordEvent(.multiBlockDetected(keyword: keyWord, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] MULTIBLOCK DETECT>> \(keyWord)")
        }
    }
    
    public func multiBlockDetectFailed(pInfo: ParsedInfo) {
        recordEvent(.multiBlockFailed(source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("[\(pInfo.lineNo)] FAILED MULTIBLOCK PARSE>> \(pInfo.line) ")
        }
    }
    
    public func comment(line: String, lineNo: Int) {
        print("[\(lineNo)] \(line)")
    }
    
    public func content(_ line: String, pInfo: ParsedInfo) {
        recordEvent(.textContent(text: line, source: sourceLocation(from: pInfo)))
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
        recordEvent(.functionCallEvaluated(expression: line, source: sourceLocation(from: pInfo)))
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
        let desc = await containers.debugDescription
        recordEvent(.parsedTreeDumped(treeName: "containers", treeDescription: desc))
        if flags.printParsedTree {
            await print(desc)
        }
    }
    
    public func ifConditionSatisfied(condition: String, pInfo: ParsedInfo) {
        recordEvent(.controlFlow(branch: .ifTrue, condition: condition, satisfied: true, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] IF Condition Satisfied>> \(pInfo.line)")
        }
    }
    
    public func elseIfConditionSatisfied(condition: String, pInfo: ParsedInfo) {
        recordEvent(.controlFlow(branch: .elseIfTrue, condition: condition, satisfied: true, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] ELSE IF Condition Satisfied>> \(pInfo.line)")
        }
    }
    
    public func elseBlockExecuting(_ pInfo: ParsedInfo) {
        recordEvent(.controlFlow(branch: .elseBlock, condition: "", satisfied: true, source: sourceLocation(from: pInfo)))
        if flags.lineByLineParsing || flags.blockByBlockParsing || flags.controlFlow {
            print("[\(pInfo.lineNo)] ELSE Block executing>> \(pInfo.line)")
        }
    }
    
    public func templateParsingStarting(name: String = "") {
        if name.isNotEmpty { recordEvent(.templateParseStarted(name: name)) }
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("TEMPLATE PARSING START -------------\n\n")
        }
    }
    
    public func templateExecutionStarting(name: String = "", pInfo: ParsedInfo? = nil) {
        if name.isNotEmpty, let pInfo {
            recordEvent(.templateStarted(name: name, source: sourceLocation(from: pInfo)))
        }
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("\n\n\n\nTEMPLATE EXECTION START -------------\n")
        }
    }
    
    public func scriptFileParsingStarting(name: String = "") {
        if name.isNotEmpty { recordEvent(.scriptParseStarted(name: name)) }
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("SCRIPT PARSING START -------------\n\n")
        }
    }
    
    public func scriptFileExecutionStarting(name: String = "", pInfo: ParsedInfo? = nil) {
        if name.isNotEmpty, let pInfo {
            recordEvent(.scriptStarted(name: name, source: sourceLocation(from: pInfo)))
        }
        if flags.lineByLineParsing || flags.blockByBlockParsing {
            print("\n\n\n\nSCRIPT TEMPLATE EXECTION START -------------\n")
        }
    }
    
    public func workingDirectoryChanged(_ path: String) {
        recordEvent(.workingDirChanged(from: "", to: path, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.changesInWorkingDirectory {
            print("Working Dir: \(path)")
        }
    }
    
    public func stopRenderingCurrentFile(_ filepath: String, pInfo: ParsedInfo) {
        recordEvent(.fileRenderStopped(path: filepath, source: sourceLocation(from: pInfo)))
        if flags.renderingStoppedInFiles {
            print("⚠️ Stop Rendering \(filepath) ...")
        }
    }
    
    public func throwErrorFromCurrentFile(_ filepath: String, err: String, pInfo: ParsedInfo) {
        recordEvent(.fatalError(message: err, source: sourceLocation(from: pInfo)))
        if flags.errorThrownInFiles {
            print("🚨 Error '\(err)' Thrown From \(filepath) ...")
        }
    }
    
    public func excludingFile(_ filepath: String) {
        recordEvent(.fileExcluded(path: filepath, reason: "include-if", source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.excludedFiles {
            print("⚠️ Excluding \(filepath) ...")
        }
    }
    
    public func generatingFile(_ filepath: String) {
        recordEvent(.fileGenerated(outputPath: filepath, templateName: nil, objectName: nil, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Generating \(filepath) ...")
        }
    }
    
    public func copyingFile(_ filepath: String) {
        recordEvent(.fileCopied(sourcePath: filepath, outputPath: filepath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Copying \(filepath) ...")
        }
    }
    
    public func copyingFile(_ filepath: String, to newFilePath: String) {
        recordEvent(.fileCopied(sourcePath: filepath, outputPath: newFilePath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Copying \(filepath) to \(newFilePath)...")
        }
    }
    
    public func copyingFileInFolder(_ filepath: String, folder: LocalFolder) {
        recordEvent(.fileCopied(sourcePath: filepath, outputPath: folder.pathString + "/" + filepath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Copying \(filepath) ...")
        }
    }
    
    public func copyingFileInFolder(_ filepath: String, to newFilePath: String, folder: LocalFolder) {
        recordEvent(.fileCopied(sourcePath: filepath, outputPath: newFilePath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Copying \(filepath) to \(newFilePath)...")
        }
    }
    
    public func copyingFolder(_ path: String) {
        recordEvent(.folderCopied(path: path, outputPath: path, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Copying folder \(path) ...")
        }
    }
    
    public func copyingFolder(_ path: String, to newPath: String) {
        recordEvent(.folderCopied(path: path, outputPath: newPath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Copying folder \(path) to \(newPath)...")
        }
    }
    
    public func renderingFolder(_ path: String, to newPath: String) {
        recordEvent(.folderRendered(path: path, outputPath: newPath, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Rendering folder \(path) to \(newPath)...")
        }
    }
    
    public func generatingFile(_ filepath: String, with template: String) {
        recordEvent(.fileGenerated(outputPath: filepath, templateName: template, objectName: nil, source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("Generating \(filepath) [template \(template)] ...")
        }
    }
    
    public func fileNotGenerated(_ filepath: String, with template: String) {
        recordEvent(.fileSkipped(path: filepath, templateName: template, reason: "not generated", source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("⚠️ File \(filepath) [template \(template)] not Generated!!!...")
        }
    }
    
    public func generatingFileInFolder(_ filepath: String, with template: String, folder: LocalFolder, pInfo: ParsedInfo) async {
        let outputPath = folder.pathString + "/" + filepath
        await recordFileGenerated(
            outputPath: outputPath,
            templateName: template,
            objectName: nil,
            workingDir: folder.pathString,
            source: sourceLocation(from: pInfo)
        )
        if flags.fileGeneration {
            print("[ \(folder.pathString) ] Generating \(filepath) [template \(template)] ...")
        }
    }
    
    public func fileNotGeneratedInFolder(_ filepath: String, with template: String, folder: LocalFolder) {
        recordEvent(.fileSkipped(path: filepath, templateName: template, reason: "not generated", source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("⚠️ [ \(folder.pathString) ]  File \(filepath) [template \(template)] not Generated!!!...")
        }
    }
    
    public func fileNotGenerated(_ filepath: String) {
        recordEvent(.fileSkipped(path: filepath, templateName: nil, reason: "not generated", source: SourceLocation(fileIdentifier: "", lineNo: 0, lineContent: "", level: 0)))
        if flags.fileGeneration {
            print("⚠️ File \(filepath) not Generated!!!...")
        }
    }
    
    public func pipelinePhaseCannotRun(_ phase: any PipelinePhase, msg: String) {
        recordEvent(.phaseSkipped(name: String(describing: type(of: phase)), reason: msg))
        print("⦻ Phase \(phase) cannot run!!!...")
        print("⦻ \(msg)!!!...")
    }
    
    public func pipelinePassCannotRun(_ pass: any PipelinePass, msg: String? = nil) {
        recordEvent(.passSkipped(name: String(describing: type(of: pass)), reason: msg))
        print("⦻ Pass \(pass) cannot run!!!...")
        if let msg {
            print("⦻ \(msg)!!!...")
        }
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
