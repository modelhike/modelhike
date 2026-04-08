import ArgumentParser
import Foundation

enum ToolExitCode: Int32 {
    case success = 0
    case validationWarnings = 1
    case validationErrors = 2
    case parseFailure = 3
    case generationFailure = 4

    var commandExitCode: ExitCode {
        ExitCode(rawValue)
    }
}
