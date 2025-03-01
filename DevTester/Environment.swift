import DiagSoup

enum Environment {
    static var debug: OutputConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)
        env.localBlueprintsPath = LocalPath(relativePath: "blueprints", basePath: env.basePath)
        
        return env
    }
    
    static var production: OutputConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)
        env.localBlueprintsPath = LocalPath(relativePath: "blueprints", basePath: env.basePath)
        
        return env
    }
}

