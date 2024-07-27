//
// StatementsLibrary.swift
// DiagSoup
// https://www.github.com/diagsoup/diagsoup
//

import Foundation

public struct StatementsLibrary {
    
    public static var statements: [any FileTemplateStmtConfig] {
        return [
            ForStmt.register, 
            IfStmt.register,
            FunctionCallStmt.register,
            
            CopyFileStmt.register,
            RenderFileWithTemplateStmt.register,
            FillAndCopyFileStmt.register,
            
            CopyFolderStmt.register,
            
            RunShellCmdStmt.register,
            ConsoleLogStmt.register,
            
            SetVarStmt.register,
            SetObjectAttributeStmt.register,
            
            SpacelessStmt.register
        ]
    }
    
}
