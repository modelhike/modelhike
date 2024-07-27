//
// MockData_Generator.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct MockData_Generator {
    func randomId() -> String {
        return UUID().uuidString.normalizeForId()
    }
    
    func randomObjectId_MongoDb() -> String {

        var timestamp = UInt32(Date().timeIntervalSince1970)
        let randomValue = (0..<5).map { _ in UInt8.random(in: 0...255) }
        let counter = (0..<3).map { _ in UInt8.random(in: 0...255) }

        var objectId = Data()
        objectId.append(Data(bytes: &timestamp, count: MemoryLayout<UInt32>.size))
        objectId.append(Data(randomValue))
        objectId.append(Data(counter))

        return objectId.toHex()

    }
}
