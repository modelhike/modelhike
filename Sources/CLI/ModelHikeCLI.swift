import ArgumentParser

@main
struct ModelHikeCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "modelhike",
        abstract: "Smart CLI for validating, explaining, inspecting, and generating from .modelhike models.",
        subcommands: [
            ValidateCommand.self,
            GenerateCommand.self,
            InlineGenerateCommand.self,
            DryRunCommand.self,
            ExplainCommand.self,
            InspectCommand.self,
            WhatDependsOnCommand.self,
            ListTypesCommand.self,
            FixCommand.self,
            PreflightCommand.self,
            ListBlueprintsCommand.self,
            SchemaInMarkdownCommand.self,
        ]
    )
}
