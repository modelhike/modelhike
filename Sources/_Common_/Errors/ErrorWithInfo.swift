//
// ErrorWithInfo.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public protocol ErrorWithMessage : Error {
    var info: String {get}
}

public protocol ErrorWithMessageAndParsedInfo : ErrorWithMessage {
    var pInfo: ParsedInfo {get}
}
