import DiagSoup

@main
struct Development {
    static func main() {
        do {
            try runTemplateStr()
            //try runCodebaseGeneration()
        } catch {
            print(error)
        }
    }
    
    static func runTemplateStr() throws {
        let templateStr = "{{ (var1 and var2) and var2}}"
        let arr:[TestData] = [TestData(name: "n1", age: 1),
                          TestData(name: "n2", age: 2),
                          TestData(name: "", age: 3)]
        
        let data: [String : Any] = ["list":arr, "var1" : true, "var2": false, "varstr": "test"]
        
        let ws = Workspace();
        if let result = ws.render(string: templateStr, data: data) {
            print(result)
        }
    }
    
    static func runCodebaseGeneration() throws {
        let ws = Workspace();
                
        ws.basePath = SystemFolder.documents.path / "diagsoup"
        //ws.debugLog.flags.fileGeneration = true
        
        try ws.loadSymbols([.typescript, .mongodb_typescript])
        
        //let modelRepo = LocalFileModelLoader(path: ws.basePath, with: ws.context)
        let modelRepo = inlineModel(ws)
        
        try ws.loadModels(from: modelRepo)
        
        let templatesPath = ws.basePath / "_gen.templates"
        let templatesRepo = LocalFileBlueprintLoader(blueprint: "nestjs-monorepo", path: templatesPath, with: ws.context)

        ws.generateCodebase(container: "APIs", usingBlueprintsFrom: templatesRepo)
    }
    
    
    private static func inlineModel(_ ws: Workspace) -> InlineModelLoader {
        return InlineModelLoader(with: ws.context) {
            InlineModel {
                """
                ===
                APIs
                ====
                + Registry Management
                
                
                === Registry Management ===
                
                Registry
                ========
                * _id: Id
                * name: String
                - desc: String
                * status: CodedValue
                * condition: CodedValue[1..*]
                * speciality: CodedValue
                - author: Reference@StaffRole
                - audit: Audit (backend)
                """
            }
            
            getCommonTypes()
        }
    }
    
    private static func getCommonTypes() -> InlineCommonTypes {
        return InlineCommonTypes {
                """
                === Commons ===
                
                CodedValue
                ==========
                * vsRef: String
                * code: String
                * display: String
                
                Reference
                =========
                * ref: String
                - type: String
                * display: String
                
                ExtendedReference
                =================
                * ref: String
                - type: String
                * display: String
                - info: Any
                - infoType: String
                - avatar: String
                - linkRef: String
                - linkType: String
                
                Audit
                ========
                - ver: String
                - crBy: Reference
                - crDt: Date
                - upDt: Date
                - upBy: Reference
                - srcId: String
                - srcApp: String
                - del: Bool
                """
            }
    }
    
}

struct TestData : DynamicMemberLookup, HasAttributes {
    public var attribs = Attributes()
    
    subscript(member: String) -> Any {
        return self.attribs["name"] as Any
    }
    
    public init(name: String, age: Int) {
        self.attribs["name"] = name
        self.attribs["age"] = name
    }
}
