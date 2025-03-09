//
//  StatementsLibrary.swift
//  ModelHike
//  https://www.github.com/modelhike/modelhike
//

import Foundation

public struct StatementsLibrary {

    public static var statements: [any FileTemplateStmtConfig] {
        return [
            ForStmt.register,
            IfStmt.register,
            FunctionCallStmt.register,

            CopyFileStmt.register,
            RenderTemplateFileStmt.register,
            FillAndCopyFileStmt.register,

            CopyFolderStmt.register,
            RenderFolderStmt.register,

            RunShellCmdStmt.register,
            ConsoleLogStmt.register,
            AnnnounceStmt.register,

            SetVarStmt.register,
            SetStrVarStmt.register,

            ThrowErrorStmt.register,
            StopRenderingCurrentTemplateStmt.register,

            SpacelessStmt.register,
        ]
    }

}
