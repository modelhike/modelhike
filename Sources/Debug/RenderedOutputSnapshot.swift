//
//  RenderedOutputSnapshot.swift
//  ModelHike
//

import Foundation

/// Serializable snapshot of one rendered output file kept in memory after generation.
/// This is used by the debug console to display generated output directly from the
/// pipeline's output tree without re-reading files back from disk.
public struct RenderedOutputRecord: Codable, Sendable {
    /// Full output path for the generated artifact.
    public let path: String
    /// In-memory rendered contents of that artifact.
    public let content: String

    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

extension PipelineState {
    /// Collects rendered output from every generation sandbox created during the run.
    /// Each sandbox owns a root `OutputFolder` tree, and this method flattens those
    /// trees into plain records that the debug server can serve to the browser UI.
    public func renderedOutputRecords() async -> [RenderedOutputRecord] {
        var records: [RenderedOutputRecord] = []

        for sandbox in generationSandboxes {
            let outputFolder = await sandbox.base_generation_dir
            records.append(contentsOf: await outputFolder.renderedOutputRecords())
        }

        return records
    }
}

extension OutputFolder {
    /// Recursively walks this output folder and all nested output folders, extracting
    /// any generated file contents that are still available in memory.
    public func renderedOutputRecords() async -> [RenderedOutputRecord] {
        var records: [RenderedOutputRecord] = []

        for item in items {
            if let record = await renderedOutputRecord(for: item) {
                records.append(record)
            }
        }

        for folder in subFolders {
            records.append(contentsOf: await folder.renderedOutputRecords())
        }

        for folderItem in folderItems {
            if let nestedOutputFolder = await folderItem.outputFolder {
                records.append(contentsOf: await nestedOutputFolder.renderedOutputRecords())
            }
        }

        return records
    }

    /// Converts one concrete `OutputFile` into a plain debug record when that file type
    /// exposes renderable in-memory content. File types that only reference external
    /// disk files and do not keep contents in memory are skipped here.
    private func renderedOutputRecord(for item: any OutputFile) async -> RenderedOutputRecord? {
        guard let outputPath = await item.outputPath else {
            return nil
        }

        let filename = await item.filename
        let fullPath = (outputPath / filename).string

        if let file = item as? TemplateRenderedFile,
           let content = await file.contents {
            return RenderedOutputRecord(path: fullPath, content: content)
        }

        if let file = item as? StaticFile {
            if let content = await file.contents {
                return RenderedOutputRecord(path: fullPath, content: content)
            }
            if let data = await file.data {
                return RenderedOutputRecord(path: fullPath, content: String(decoding: data, as: UTF8.self))
            }
            return nil
        }

        if let file = item as? PlaceHolderFile,
           let content = await file.contents {
            return RenderedOutputRecord(path: fullPath, content: content)
        }

        if let file = item as? OutputDocumentFile,
           let content = await file.contents {
            return RenderedOutputRecord(path: fullPath, content: content)
        }

        return nil
    }
}
