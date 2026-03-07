//
//  HTTPTypes.swift
//  DevTester
//

import Foundation

struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data?

    init?(data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        let lines = string.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }

        method = String(parts[0])
        path = String(parts[1])

        var headers: [String: String] = [:]
        var headerEnd = 1
        for i in 1..<lines.count {
            let line = lines[i]
            if line.isEmpty { headerEnd = i; break }
            let hParts = line.split(separator: ":", maxSplits: 1)
            if hParts.count == 2 {
                let key = String(hParts[0]).trimmingCharacters(in: .whitespaces).lowercased()
                let value = String(hParts[1]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }
        self.headers = headers

        let bodyStartIndex = lines.index(after: headerEnd)
        if bodyStartIndex < lines.endIndex {
            let bodyStart = lines[bodyStartIndex...].joined(separator: "\r\n")
            body = bodyStart.isEmpty ? nil : bodyStart.data(using: .utf8)
        } else {
            body = nil
        }
    }
}

struct HTTPResponse {
    static func ok(body: String, contentType: String = "application/json") -> Data {
        let bodyData = body.data(using: .utf8)!
        return buildResponse(
            statusLine: "HTTP/1.1 200 OK",
            headers: [
                "Content-Type: \(contentType)",
                "Content-Length: \(bodyData.count)",
                "Connection: close",
                "Access-Control-Allow-Origin: *"
            ],
            body: bodyData
        )
    }

    static func ok(body: Data, contentType: String = "application/json") -> Data {
        buildResponse(
            statusLine: "HTTP/1.1 200 OK",
            headers: [
                "Content-Type: \(contentType)",
                "Content-Length: \(body.count)",
                "Connection: close",
                "Access-Control-Allow-Origin: *"
            ],
            body: body
        )
    }

    static func notFound() -> Data {
        buildResponse(
            statusLine: "HTTP/1.1 404 Not Found",
            headers: [
                "Content-Length: 0",
                "Connection: close",
                "Access-Control-Allow-Origin: *"
            ],
            body: Data()
        )
    }

    static func optionsPreflight() -> Data {
        buildResponse(
            statusLine: "HTTP/1.1 204 No Content",
            headers: [
                "Connection: close",
                "Access-Control-Allow-Origin: *",
                "Access-Control-Allow-Methods: GET, POST, OPTIONS",
                "Access-Control-Allow-Headers: Content-Type"
            ],
            body: Data()
        )
    }

    static func websocketUpgrade(acceptKey: String) -> Data {
        buildResponse(
            statusLine: "HTTP/1.1 101 Switching Protocols",
            headers: [
                "Upgrade: websocket",
                "Connection: Upgrade",
                "Sec-WebSocket-Accept: \(acceptKey)",
                "Access-Control-Allow-Origin: *"
            ],
            body: Data()
        )
    }

    static func notImplemented(body: String = "Not Implemented") -> Data {
        let data = body.data(using: .utf8)!
        return buildResponse(
            statusLine: "HTTP/1.1 501 Not Implemented",
            headers: [
                "Content-Type: text/plain",
                "Content-Length: \(data.count)",
                "Connection: close"
            ],
            body: data
        )
    }

    private static func buildResponse(statusLine: String, headers: [String], body: Data) -> Data {
        let cacheHeaders = [
            "Cache-Control: no-store, no-cache, must-revalidate, max-age=0",
            "Pragma: no-cache",
            "Expires: 0"
        ]
        let head = ([statusLine] + headers + cacheHeaders + ["", ""]).joined(separator: "\r\n")
        return Data(head.utf8) + body
    }
}
