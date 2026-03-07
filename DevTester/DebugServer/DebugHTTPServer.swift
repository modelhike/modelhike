//
//  DebugHTTPServer.swift
//  DevTester
//

import Foundation
import Network
import ModelHike
import CommonCrypto

actor DebugHTTPServer {
    private let session: DebugSession
    private let renderedOutputs: [RenderedOutputRecord]
    private var listener: NWListener?
    private let port: UInt16
    private var isRunning = false
    private let recorder: DefaultDebugRecorder?
    private let pipeline: Pipeline?
    private let devAssetsPath: String?

    init(session: DebugSession, recorder: DefaultDebugRecorder? = nil, pipeline: Pipeline? = nil, renderedOutputs: [RenderedOutputRecord] = [], port: UInt16 = 4800, devAssetsPath: String? = nil) {
        self.session = session
        self.renderedOutputs = renderedOutputs
        self.recorder = recorder
        self.pipeline = pipeline
        self.port = port
        self.devAssetsPath = devAssetsPath
    }

    private func trace(_ message: String) {
        print("[DebugHTTPServer] \(message)")
    }

    private func preview(_ data: Data, limit: Int = 200) -> String {
        let prefix = data.prefix(limit)
        return String(decoding: prefix, as: UTF8.self)
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    func start() async throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        isRunning = true

        listener?.stateUpdateHandler = { state in
            print("[DebugHTTPServer] listener state: \(state)")
            if case .failed(let error) = state {
                print("[DebugHTTPServer] listener failed: \(error)")
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            Task {
                await self?.handleConnection(connection)
            }
        }

        listener?.start(queue: .main)
        print("🔍 Debug console: http://localhost:\(port)")
    }

    func stop() async {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) async {
        trace("accepted connection from \(String(describing: connection.endpoint))")
        connection.start(queue: .global())
        var buffer = Data()
        let chunkSize = 65536

        while isRunning {
            let data = await withCheckedContinuation { (cont: CheckedContinuation<Data?, Never>) in
                connection.receive(minimumIncompleteLength: 1, maximumLength: chunkSize) { data, _, isComplete, error in
                    if let data, !data.isEmpty {
                        print("[DebugHTTPServer] received \(data.count) bytes, complete=\(isComplete), error=\(String(describing: error))")
                        cont.resume(returning: data)
                    } else if error != nil {
                        print("[DebugHTTPServer] receive error: \(String(describing: error))")
                        cont.resume(returning: nil)
                    } else {
                        print("[DebugHTTPServer] receive returned empty chunk, complete=\(isComplete)")
                        cont.resume(returning: Data())
                    }
                }
            }
            guard let data, !data.isEmpty else { break }
            buffer.append(data)
            if data.count < chunkSize || buffer.contains(Data("\r\n\r\n".utf8)) {
                break
            }
        }

        trace("request buffer size=\(buffer.count), preview=\(preview(buffer))")
        let response = await route(requestData: buffer)
        trace("sending response bytes=\(response.count), preview=\(preview(response))")
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            connection.send(content: response, completion: .contentProcessed { error in
                print("[DebugHTTPServer] send completed, error=\(String(describing: error))")
                cont.resume()
            })
        }
        trace("closing connection")
        connection.cancel()
    }

    private func route(requestData: Data) async -> Data {
        guard let request = HTTPRequest(data: requestData) else {
            trace("failed to parse HTTP request, preview=\(preview(requestData))")
            return HTTPResponse.notFound()
        }
        trace("parsed request method=\(request.method) path=\(request.path) headers=\(request.headers)")

        switch request.method {
        case "OPTIONS":
            return HTTPResponse.optionsPreflight()
        case "GET":
            if request.path.hasPrefix("/ws") {
                return serveWebSocketUpgrade(request: request)
            }
            return await handleGet(path: request.path)
        case "POST":
            return await handlePost(path: request.path, body: request.body)
        default:
            return HTTPResponse.notFound()
        }
    }

    private func handleGet(path: String) async -> Data {
        if path.hasPrefix("/api/memory/") {
            let indexStr = String(path.dropFirst("/api/memory/".count))
            if let index = Int(indexStr), let recorder {
                let vars = await recorder.reconstructState(atEventIndex: index)
                if let data = try? JSONEncoder().encode(vars) {
                    return HTTPResponse.ok(body: data)
                }
            }
        }
        let pathWithoutQuery = path.split(separator: "?").first.map(String.init) ?? path
        if pathWithoutQuery.hasPrefix("/api/source/") {
            let rawIdentifier = String(pathWithoutQuery.dropFirst("/api/source/".count))
            return serveSource(identifier: decodePathComponent(rawIdentifier))
        }
        if pathWithoutQuery.hasPrefix("/api/generated-file/") {
            let indexStr = String(pathWithoutQuery.dropFirst("/api/generated-file/".count))
            if let index = Int(indexStr) {
                return serveGeneratedFile(at: index)
            }
            return HTTPResponse.notFound()
        }
        switch pathWithoutQuery {
        case "/", "":
            return serveIndexHTML()
        case "/api/session":
            return serveSession()
        case "/api/model":
            return serveModel()
        case "/api/events":
            return serveEvents()
        case "/api/files":
            return serveFiles()
        default:
            break
        }
        return HTTPResponse.notFound()
    }

    private func handlePost(path: String, body: Data?) async -> Data {
        switch path {
        case "/api/evaluate":
            return await serveEvaluate(body: body)
        default:
            return HTTPResponse.notFound()
        }
    }

    private func serveIndexHTML() -> Data {
        if let devPath = devAssetsPath {
            let url = URL(fileURLWithPath: devPath).appendingPathComponent("debug-console.html")
            if let data = try? Data(contentsOf: url),
               let html = String(data: data, encoding: .utf8) {
                trace("serving debug-console.html from dev assets: \(url.path), bytes=\(data.count)")
                return HTTPResponse.ok(body: html, contentType: "text/html")
            }
            trace("failed to load dev asset html from \(url.path)")
        }

        let bundleCandidates: [URL?] = [
            Bundle.module.url(forResource: "debug-console", withExtension: "html", subdirectory: "Assets"),
            Bundle.module.url(forResource: "debug-console", withExtension: "html")
        ]

        for candidate in bundleCandidates {
            if let url = candidate,
               let data = try? Data(contentsOf: url),
               let html = String(data: data, encoding: .utf8) {
                trace("serving debug-console.html from bundle: \(url.path), bytes=\(data.count)")
                return HTTPResponse.ok(body: html, contentType: "text/html")
            }
        }
        trace("serving fallback html")
        let fallback = """
        <!DOCTYPE html><html><head><title>ModelHike Debug</title></head><body>
        <h1>ModelHike Debug Console</h1>
        <p>Session: \(session.events.count) events. <a href="/api/session">Download JSON</a></p>
        </body></html>
        """
        return HTTPResponse.ok(body: fallback, contentType: "text/html")
    }

    private func serveSession() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(session) else {
            return HTTPResponse.ok(body: "{}")
        }
        return HTTPResponse.ok(body: data)
    }

    private func serveModel() -> Data {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(session.model) else {
            return HTTPResponse.ok(body: "{}")
        }
        return HTTPResponse.ok(body: data)
    }

    private func serveEvents() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(session.events) else {
            return HTTPResponse.ok(body: "[]")
        }
        return HTTPResponse.ok(body: data)
    }

    private func serveFiles() -> Data {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(session.files) else {
            return HTTPResponse.ok(body: "[]")
        }
        return HTTPResponse.ok(body: data)
    }

    private func serveWebSocketUpgrade(request: HTTPRequest) -> Data {
        let upgrade = request.headers["upgrade"] ?? ""
        let key = request.headers["sec-websocket-key"] ?? ""
        guard upgrade.lowercased().contains("websocket"), !key.isEmpty else {
            return HTTPResponse.notImplemented(body: "WebSocket upgrade requires Upgrade: websocket and Sec-WebSocket-Key")
        }
        let magic = "258EAFA5-E914-47DA-95CA-C5AB0DC36911"
        let combined = key + magic
        guard let combinedData = combined.data(using: .utf8) else {
            return HTTPResponse.notImplemented(body: "Invalid key")
        }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        combinedData.withUnsafeBytes { buffer in
            _ = CC_SHA1(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        let acceptKey = Data(hash).base64EncodedString()
        return HTTPResponse.websocketUpgrade(acceptKey: acceptKey)
    }

    private func decodePathComponent(_ value: String) -> String {
        value.removingPercentEncoding ?? value
    }

    private func sourceFile(for identifier: String) -> SourceFile? {
        if let file = session.sourceFiles.first(where: { $0.identifier == identifier }) {
            return file
        }

        let normalized = identifier.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let matches = session.sourceFiles.filter { file in
            let candidate = file.identifier.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return candidate == normalized
                || candidate.hasSuffix("/" + normalized)
                || normalized.hasSuffix("/" + candidate)
        }

        if matches.count == 1 {
            return matches[0]
        }

        let extensionAwareMatches = session.sourceFiles.filter { file in
            let candidate = file.identifier.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return candidate == normalized + ".teso"
                || candidate == normalized + ".ss"
                || candidate.hasSuffix("/" + normalized + ".teso")
                || candidate.hasSuffix("/" + normalized + ".ss")
        }

        if extensionAwareMatches.count == 1 {
            return extensionAwareMatches[0]
        }

        return nil
    }

    private func serveSource(identifier: String) -> Data {
        guard let file = sourceFile(for: identifier) else {
            return HTTPResponse.notFound()
        }
        let encoder = JSONEncoder()
        struct SourceResponse: Encodable {
            let identifier: String
            let content: String
            let lineCount: Int
        }
        let response = SourceResponse(identifier: file.identifier, content: file.content, lineCount: file.lineCount)
        guard let data = try? encoder.encode(response) else {
            return HTTPResponse.notFound()
        }
        return HTTPResponse.ok(body: data)
    }

    private func normalizePath(_ path: String) -> String {
        var normalized = path.replacingOccurrences(of: "\\", with: "/")
        while normalized.contains("//") {
            normalized = normalized.replacingOccurrences(of: "//", with: "/")
        }
        if normalized.count > 1, normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    private func generatedFileCandidates(for record: GeneratedFileRecord) -> [String] {
        let outputRoot = URL(fileURLWithPath: session.config.outputPath)
        var candidates: [String] = []

        if record.outputPath.hasPrefix("/") {
            candidates.append(record.outputPath)
        } else {
            candidates.append(outputRoot.appendingPathComponent(record.outputPath).path)
        }

        if !record.workingDir.isEmpty {
            if record.workingDir.hasPrefix("/") {
                let absoluteWorkingDir = URL(fileURLWithPath: record.workingDir)
                candidates.append(absoluteWorkingDir.appendingPathComponent(record.outputPath).path)

                let outputRelativeWorkingDir = record.workingDir.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                candidates.append(outputRoot.appendingPathComponent(outputRelativeWorkingDir).appendingPathComponent(record.outputPath).path)
            } else {
                candidates.append(outputRoot.appendingPathComponent(record.workingDir).appendingPathComponent(record.outputPath).path)
            }
        }

        return Array(Set(candidates.map(normalizePath)))
    }

    private func serveGeneratedFile(at index: Int) -> Data {
        guard session.files.indices.contains(index) else {
            return HTTPResponse.notFound()
        }

        let record = session.files[index]
        let candidatePaths = generatedFileCandidates(for: record)
        guard let renderedOutput = renderedOutputs.first(where: { candidatePaths.contains(normalizePath($0.path)) }) else {
            return HTTPResponse.notFound()
        }
        let encoder = JSONEncoder()

        struct GeneratedFileResponse: Encodable {
            let path: String
            let resolvedPath: String
            let content: String
            let lineCount: Int
        }

        let response = GeneratedFileResponse(
            path: record.outputPath,
            resolvedPath: renderedOutput.path,
            content: renderedOutput.content,
            lineCount: renderedOutput.content.components(separatedBy: .newlines).count
        )

        guard let encoded = try? encoder.encode(response) else {
            return HTTPResponse.notFound()
        }

        return HTTPResponse.ok(body: encoded)
    }

    private func serveEvaluate(body: Data?) async -> Data {
        struct EvalRequest: Decodable {
            let expression: String?
            let eventIndex: Int?
        }
        struct EvalResponse: Encodable {
            let result: String?
            let error: String?
        }
        guard let body,
              let request = try? JSONDecoder().decode(EvalRequest.self, from: body),
              let expr = request.expression, !expr.isEmpty else {
            return HTTPResponse.ok(body: "{\"error\":\"Missing expression\"}")
        }
        guard let pipeline, let recorder else {
            return HTTPResponse.ok(body: "{\"error\":\"Expression playground requires pipeline and recorder\"}")
        }
        let eventIndex = request.eventIndex ?? max(0, session.events.count - 1)
        let flatVars = await recorder.reconstructState(atEventIndex: eventIndex)
        let data = buildNestedVars(from: flatVars)
        var template = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        if !template.contains("{{") {
            template = "{{ \(template) }}"
        }
        do {
            if let result = try await pipeline.render(string: template, data: data) {
                let response = EvalResponse(result: result, error: nil)
                let encoded = try JSONEncoder().encode(response)
                return HTTPResponse.ok(body: encoded)
            }
            let response = EvalResponse(result: nil, error: "Empty result")
            let encoded = try JSONEncoder().encode(response)
            return HTTPResponse.ok(body: encoded)
        } catch {
            let response = EvalResponse(result: nil, error: String(describing: error))
            let encoded = (try? JSONEncoder().encode(response)) ?? Data("{\"error\":\"\(String(describing: error).replacingOccurrences(of: "\"", with: "\\\""))\"}".utf8)
            return HTTPResponse.ok(body: encoded)
        }
    }

    private func buildNestedVars(from flat: [String: String]) -> [String: Sendable] {
        var result: [String: Sendable] = [:]
        for (key, value) in flat {
            let parts = key.split(separator: ".").map(String.init)
            guard !parts.isEmpty else { continue }
            setNested(result: &result, path: parts, value: value)
        }
        return result
    }

    private func setNested(result: inout [String: Sendable], path: [String], value: String) {
        guard path.count > 1 else {
            result[path[0]] = value
            return
        }
        let key = path[0]
        let rest = Array(path.dropFirst())
        if result[key] == nil {
            result[key] = [String: Sendable]()
        }
        var child = result[key] as! [String: Sendable]
        setNested(result: &child, path: rest, value: value)
        result[key] = child
    }
}
