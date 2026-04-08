import Foundation
import Logging
import MCP

struct ChildProcessLaunchConfiguration: Codable, Sendable {
    let executablePath: String
    let arguments: [String]
    let workingDirectory: String
    let environment: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case executablePath
        case arguments
        case workingDirectory
    }

    init(
        executablePath: String,
        arguments: [String],
        workingDirectory: String,
        environment: [String: String]?
    ) {
        self.executablePath = executablePath
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environment = environment
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        executablePath = try container.decode(String.self, forKey: .executablePath)
        arguments = try container.decode([String].self, forKey: .arguments)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        environment = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(executablePath, forKey: .executablePath)
        try container.encode(arguments, forKey: .arguments)
        try container.encode(workingDirectory, forKey: .workingDirectory)
    }
}

actor ChildProcessTransport: Transport {
    nonisolated let logger: Logger

    private let configuration: ChildProcessLaunchConfiguration
    private let stdoutBuffer: LineDelimitedMessageBuffer
    private let stderrBuffer = TextCaptureBuffer()
    private let messageStream: AsyncThrowingStream<Data, Swift.Error>
    private let messageContinuation: AsyncThrowingStream<Data, Swift.Error>.Continuation

    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var isConnected = false

    init(
        configuration: ChildProcessLaunchConfiguration,
        logger: Logger = Logger(label: "devtester.mcp.transport")
    ) {
        self.configuration = configuration
        self.logger = logger

        var continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation!
        self.messageStream = AsyncThrowingStream { continuation = $0 }
        self.messageContinuation = continuation
        self.stdoutBuffer = LineDelimitedMessageBuffer(continuation: continuation)
    }

    func connect() async throws {
        guard !isConnected else { return }

        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: configuration.executablePath)
        process.arguments = configuration.arguments
        process.currentDirectoryURL = URL(fileURLWithPath: configuration.workingDirectory, isDirectory: true)
        process.environment = configuration.environment
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutHandle = stdoutPipe.fileHandleForReading
        let stderrHandle = stderrPipe.fileHandleForReading
        let stdoutBuffer = self.stdoutBuffer
        let stderrBuffer = self.stderrBuffer

        stdoutHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                stdoutBuffer.finish()
                return
            }
            stdoutBuffer.append(data)
        }

        stderrHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            stderrBuffer.append(data)
        }

        try process.run()

        self.process = process
        self.stdinHandle = stdinPipe.fileHandleForWriting
        self.stdoutHandle = stdoutHandle
        self.stderrHandle = stderrHandle
        self.isConnected = true
    }

    func disconnect() async {
        guard isConnected else { return }

        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil

        try? stdinHandle?.close()
        try? stdoutHandle?.close()
        try? stderrHandle?.close()

        if let process, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }

        stdoutBuffer.finish()

        process = nil
        stdinHandle = nil
        stdoutHandle = nil
        stderrHandle = nil
        isConnected = false
    }

    func send(_ data: Data) async throws {
        guard isConnected, let stdinHandle else {
            throw MCPTesterError.transport("Client transport is not connected.")
        }

        var message = data
        message.append(UInt8(ascii: "\n"))

        do {
            try stdinHandle.write(contentsOf: message)
        } catch {
            throw MCPTesterError.transport("Failed to write to child process stdin: \(error)")
        }
    }

    func receive() -> AsyncThrowingStream<Data, Swift.Error> {
        messageStream
    }

    func stderrTail(maxBytes: Int = 4096) -> String {
        stderrBuffer.snapshot(maxBytes: maxBytes)
    }
}

private final class LineDelimitedMessageBuffer: @unchecked Sendable {
    private let continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation
    private let lock = NSLock()
    private var pending = Data()
    private var finished = false

    init(continuation: AsyncThrowingStream<Data, Swift.Error>.Continuation) {
        self.continuation = continuation
    }

    func append(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }

        guard !finished else { return }

        pending.append(data)

        while let newlineIndex = pending.firstIndex(of: UInt8(ascii: "\n")) {
            var line = Data(pending[..<newlineIndex])
            pending.removeSubrange(...newlineIndex)

            if line.last == UInt8(ascii: "\r") {
                line.removeLast()
            }

            if !line.isEmpty {
                continuation.yield(line)
            }
        }
    }

    func finish() {
        lock.lock()
        defer { lock.unlock() }

        guard !finished else { return }

        if !pending.isEmpty {
            continuation.yield(pending)
            pending.removeAll()
        }

        finished = true
        continuation.finish()
    }
}

private final class TextCaptureBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()

    func append(_ data: Data) {
        lock.lock()
        buffer.append(data)
        lock.unlock()
    }

    func snapshot(maxBytes: Int) -> String {
        lock.lock()
        let data = buffer.suffix(maxBytes)
        lock.unlock()
        return String(decoding: data, as: UTF8.self)
    }
}
