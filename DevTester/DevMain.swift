import ModelHike

@main
struct Development {
    static func main() async {
        do {
            try runTemplateStr()
            //try await runCodebaseGeneration()
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
        
        let ws = Pipelines.empty
        if let result = try ws.render(string: templateStr, data: data) {
            print(result)
        }
    }
    
    static func runCodebaseGeneration() async throws {
        let pipeline = Pipelines.codegen
        var config = Environment.debug
        config.containersToOutput = ["APIs"]

        //for debugging
        //config.flags.fileGeneration = true
        
//        config.events.onBeforeRenderTemplateFile = { filename, templateName, pInfo in
//            //print(filename)
//            
//            if filename.is("user.java") {
//                pInfo.ctx.debugLog.flags.lineByLineParsing = true
//            } else {
//                pInfo.ctx.debugLog.flags.lineByLineParsing = false
//            }
//            
//            return true
//        }
        
        
//        config.events.onBeforeRenderFile = { filename, context in
//            if filename.lowercased() == "MonitoredLiveAirport".lowercased() {
//                print("rendering \(filename)")
//            }
//
//            return true
//        }
//        
//        config.events.onBeforeParseTemplate = { templatename, context in
//            if templatename.lowercased() == "entity.validator.teso".lowercased() {
//                print("rendering \(templatename)")
//            }
//        }
//
//        config.events.onBeforeExecuteTemplate = { templatename, context in
//            if templatename.lowercased() == "entity.validator.teso".lowercased() {
//                print("rendering \(templatename)")
//            }
//        }
//        
//        config.events.onStartParseObject = { objname, pInfo in
//            print(objname)
//            if objname.lowercased() == "airport".lowercased() {
//                pInfo.ctx.debugLog.flags.lineByLineParsing = true
//            } else {
//                pInfo.ctx.debugLog.flags.lineByLineParsing = false
//            }
//        }
                  
        //continue run
        try await pipeline.run(using: config)
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
    
    public func getValueOf(property propname: String, with pInfo: ParsedInfo) throws -> Any {
        return self.attribs[propname] as Any
    }
    
    public init(name: String, age: Int) {
        self.attribs["name"] = name
        self.attribs["age"] = name
    }
}
