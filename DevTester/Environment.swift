import DiagSoup

enum Environment {
    static var debug: PipelineConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)

        return env
    }
    
    static var production: PipelineConfig {
        var env = PipelineConfig()

        env.basePath = LocalPath(relativePath: "diagsoup", basePath: SystemFolder.documents.path)
        
        return env
    }
}

