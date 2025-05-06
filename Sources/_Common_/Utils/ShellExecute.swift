//
//  Shell.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

#if os(macOS)
public enum Shell {
    public static func execute(command cmd: String, options: Options? = nil) -> Result {
        let process = Process()
        process.launchPath = "/bin/bash"
        process.arguments = ["-c"] + [cmd]
        
        if let options = options, let cwd = options.workingDirectory {
            process.currentDirectoryURL = cwd
        }

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return Result(failedToRun: true, error: "Process failed: \(error.localizedDescription)")
        }

        let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()

        // Wait for process to finish. Must be called after `readDataToEndOfFile` because otherwise,
        // the process will hang if a pipe is full
        process.waitUntilExit()

        let exitCode = process.terminationStatus
        let failed = exitCode != 0
        if failed {
            return Result(
                failed: failed,
                exitCode: exitCode,
                stdout: stdoutData,
                stderr: stderrData
            )
        } else {
            return Result(
                stdout: stdoutData,
                stderr: stderrData
            )
        }
    }
    
    public struct Result {
        public let failed: Bool
        public let exitCode: Int32
        public let stdout: String?
        public let stderr: String?
        
        public init(failed: Bool = false, exitCode: Int32 = 0, stdout stdoutData: Data, stderr stderrData: Data) {
            self.failed = failed
            self.exitCode = exitCode
            
            var stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
            var stderrString = String(data: stderrData, encoding: .utf8) ?? ""
            
            //strip any trailing newlines in the output
            if stdoutString.hasSuffix("\n") {
                stdoutString.removeLast()
            }
            if stderrString.hasSuffix("\n") {
                stderrString.removeLast()
            }
            
            self.stdout = stdoutString
            self.stderr = stderrString
        }
        
        public init(failedToRun: Bool, error: String) {
            self.failed = failedToRun
            self.exitCode = -1
            
            self.stdout = nil
            self.stderr = error
        }
    }
    
    public struct Options {
        public let workingDirectory: URL?
        
        public init(workingDirectory: String) {
            self.workingDirectory = URL(fileURLWithPath: workingDirectory)
        }
    }
}
#else
// iOS/iPadOS/watchOS/tvOS implementation
public enum Shell {
    public static func execute(command cmd: String, options: Options? = nil) -> Result {
        return Result(failedToRun: true, error: "Shell commands are not supported on this platform.")
    }
    
    public struct Result {
        public let failed: Bool
        public let exitCode: Int32
        public let stdout: String?
        public let stderr: String?
        
        public init(failed: Bool = false, exitCode: Int32 = 0, stdout: String? = nil, stderr: String? = nil) {
            self.failed = failed
            self.exitCode = exitCode
            self.stdout = stdout
            self.stderr = stderr
        }
        
        public init(failedToRun: Bool, error: String) {
            self.failed = failedToRun
            self.exitCode = -1
            self.stdout = nil
            self.stderr = error
        }
    }
    
    public struct Options {
        public let workingDirectory: URL?
        
        public init(workingDirectory: String) {
            self.workingDirectory = URL(fileURLWithPath: workingDirectory)
        }
    }
}
#endif
