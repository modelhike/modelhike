import Foundation
import Testing
@testable import ModelHikeKit

@Test
func resolvesMainTconfigWhenPresent() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("modelhike-smart-cli-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let preferredURL = directory.appendingPathComponent(ModelSupportFiles.preferredConfigFileName)

    try "preferred".write(to: preferredURL, atomically: true, encoding: .utf8)

    #expect(ModelSupportFiles.configFileURL(in: directory)?.lastPathComponent == ModelSupportFiles.preferredConfigFileName)
}

@Test
func ignoresNonMainTconfigNames() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("modelhike-smart-cli-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let otherURL = directory.appendingPathComponent("other.tconfig")
    try "other".write(to: otherURL, atomically: true, encoding: .utf8)

    #expect(ModelSupportFiles.configFileURL(in: directory) == nil)
}
