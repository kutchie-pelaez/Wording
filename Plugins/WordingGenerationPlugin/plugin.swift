import Foundation
import PackagePlugin

enum WordingGenerationPluginError: Error {
    case noConfigFound
}

@main
struct WordingGenerationPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let configs = target
            .sourceFiles(withSuffix: ".yml")
            .filter { $0.path.stem.starts(with: "wording") }

        let configForGeneration: File

        if let enConfig = configs.first(where: { $0.path.stem == "wording_en" }) {
            configForGeneration = enConfig
        } else if let firstConfig = configs.first {
            configForGeneration = firstConfig
        } else {
            throw WordingGenerationPluginError.noConfigFound
        }

        return [
            try generationCommand(for: configForGeneration, context: context)
        ]
    }

    private func generationCommand(for wordingConfig: File, context: PluginContext) throws -> Command {
        let wordingPath = wordingConfig.path
        let wordingName = wordingPath.lastComponent
        let generatedFileName = "Wording.swift"
        let generatedFilePath = context.pluginWorkDirectory.appending(generatedFileName)
        let executablePath = try context.tool(named: "WordingGenerationPluginTool").path

        return .buildCommand(
            displayName: "Generating \(generatedFileName) from \(wordingName) config",
            executable: executablePath,
            arguments: [wordingPath, generatedFilePath],
            inputFiles: [wordingPath],
            outputFiles: [generatedFilePath]
        )
    }
}
