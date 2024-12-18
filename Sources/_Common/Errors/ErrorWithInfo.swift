//
// ErrorWithInfo.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

public protocol ErrorWithInfo : Error {
    var info: String {get}
}
