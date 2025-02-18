import DiagSoup

enum Environment {
    static var debug: PipelineConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)
        env.localBlueprintsPath = LocalPath(relativePath: "blueprints", basePath: env.basePath)
        
        return env
    }
    
    static var production: PipelineConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)
        env.localBlueprintsPath = LocalPath(relativePath: "blueprints", basePath: env.basePath)
        
        return env
    }
}

