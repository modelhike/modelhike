//
//  ErrorWithInfo.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

public protocol ErrorWithMessage : Error, Sendable {
    var info: String {get}
}

public protocol ErrorWithMessageAndParsedInfo : ErrorWithMessage {
    var pInfo: ParsedInfo {get}
}
