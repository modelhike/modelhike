import Testing
@testable import ModelHikeKit

@Test
func explainBuildsContainerAndEntitySummary() async throws {
        let engine = ModelHikeEngine()
        let result = try await engine.explain(.content(
            """
            ===
            APIs
            ====
            + Billing

            === Billing ===

            Subscription
            ============
            * _id: String
            * name: String
            - status: String
            """
        ))

        #expect(result.summary.containerCount == 1)
        #expect(result.summary.entityCount == 1)
        #expect(result.containers.first?.displayName == "APIs")
        #expect(result.containers.first?.modules.first?.objects.first?.displayName == "Subscription")
}
