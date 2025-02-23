/**
 *  Files
 *
 *  Copyright (c) 2017-2019 John Sundell. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */
//source:  https://github.com/JohnSundell/Files/blob/master/Sources/Files.swift

import Foundation

/// Error type thrown by all of Files' throwing APIs.
public struct FilesError<Reason>: ErrorWithMessage {
    /// The absolute path that the error occured at.
    public var path: String
    /// The reason that the error occured.
    public var reason: Reason

    public var message: String?
    
    public var info: String {
        if let msg = message {
            return msg
        } else {
            return """
        File encountered an error at '\(path)'.
        Reason: \(reason)
        """
            }
    }
    
    /// Initialize an instance with a path and a reason.
    /// - parameter path: The absolute path that the error occured at.
    /// - parameter reason: The reason that the error occured.
    public init(path: String, reason: Reason, msg: String? = nil) {
        self.path = path
        self.reason = reason
        self.message = msg
    }
    
    public init(path: any Path, reason: Reason, msg: String? = nil) {
        self.path = path.string
        self.reason = reason
        self.message = msg
    }
}

/// Enum listing reasons that a location manipulation could fail.
public enum LocationErrorReason {
    /// The location couldn't be found.
    case missing
    /// An empty path was given when refering to a file.
    case emptyFilePath
    /// The user attempted to rename the file system's root folder.
    case cannotRenameRoot
    /// A rename operation failed with an underlying system error.
    case renameFailed(Error)
    /// A move operation failed with an underlying system error.
    case moveFailed(Error)
    /// A copy operation failed with an underlying system error.
    case copyFailed(Error)
    /// A delete operation failed with an underlying system error.
    case deleteFailed(Error)
    /// A search path couldn't be resolved within a given domain.
    case unresolvedSearchPath(
        FileManager.SearchPathDirectory,
        domain: FileManager.SearchPathDomainMask
    )
}

/// Enum listing reasons that a write operation could fail.
public enum WriteErrorReason {
    /// An empty path was given when writing or creating a location.
    case emptyPath
    /// A folder couldn't be created because of an underlying system error.
    case folderCreationFailed(Error)
    /// A file couldn't be created.
    case fileCreationFailed
    /// A file couldn't be written to because of an underlying system error.
    case writeFailed(Error)
    /// Failed to encode a string into binary data.
    case stringEncodingFailed(String)
}

/// Enum listing reasons that a read operation could fail.
public enum ReadErrorReason {
    /// A file couldn't be read because of an underlying system error.
    case readFailed(Error)
    /// Failed to decode a given set of data into a string.
    case stringDecodingFailed
    /// Encountered a string that doesn't contain an integer.
    case notAnInt(String)
}

/// Error thrown by location operations - such as find, move, copy and delete.
public typealias LocationError = FilesError<LocationErrorReason>
/// Error thrown by write operations - such as file/folder creation.
public typealias WriteError = FilesError<WriteErrorReason>
/// Error thrown by read operations - such as when reading a file's contents.
public typealias ReadError = FilesError<ReadErrorReason>

public typealias AppError = FilesError<ReadErrorReason>
