# ModelHike – Deterministic App Generation from Plain-Text Models (AI-in-Loop Optional)

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](#) ![License: MIT](https://img.shields.io/badge/license-MIT-blue) [![Security](https://img.shields.io/badge/security-policy-blue)](SECURITY.md)

> **Declarative Apps in Markdown. Generate Production-grade, Git-friendly source code, docs & diagrams -— with (optional) AI-in-Loop.**

---

## TL;DR
ModelHike is an open-source toolchain for building *declarative apps*: turn plain-text, Markdown-flavoured *software models* into production-grade, Git-friendly source code, documentation, and diagrams. **All the implementation details — controllers, data access, framework wiring, etc — are treated as boilerplate and generated for you, so your team can concentrate on the real gold: domain rules & business logic.** This keeps architecture and implementation in sync, and produces fully deterministic artifacts.

It *combines* the raw speed of **AI-assisted prototyping** with the safety of **template-driven determinism**: explore rapidly while things are fluid, then lock in templates for repeatable, reviewable builds.

No black-box surprises —- AI is in-loop (strictly optional) but never out of control.

Result: AI accelerates the unknowns, but every production build is template-driven, diffable, and CI-safe.

> 🚀 **Speed + Safety:** Use AI to sketch and refactor at warp speed, then let templates take over for bullet-proof builds.

## Real-World Impact

| Scenario | Outcome |
|----------|---------|
| Greenfield microservice (≈3 KLOC baseline) | **78 %** less handwritten boilerplate, PR merged **5 days sooner** |
| Legacy import (≈60 KLOC) | Onboarding time cut by **30 %**; zero architecture drift after 3 months |

*Based on internal case studies (2024).*

---

## Table of Contents
- [Why It Matters](#why-it-matters-to-senior-engineers)
- [AI Optional](#ai-optional-exactly-where-we-use-it)
- [Architecture](#architecture-at-a-glance)
- [Quick Walkthrough](#hello-production—30-second-walkthrough)
- [GUI Quick-Start](#gui-quick-start-optional)
- [Extensibility](#extensibility)
- [Power Features](#power-features-that-wow)
- [Security & Privacy](#security--privacy)
- [Zero-Boilerplate Tests](#zero-boilerplate-tests)
- [ADR Scaffold](#adr-scaffold-architecture-decision-records)
- [System Requirements](#system-requirements)
- [Glossary](#glossary)

---

## Why It Matters to Senior Engineers
| Pain Point | Traditional Approach | ModelHike Approach |
|------------|---------------------|--------------------|
| Architecture & code drift | Confluence docs rot, tribal knowledge | Single source-of-truth models keep design ↔ code aligned |
| Boilerplate & onboarding | Copy-paste patterns, code reviews on plumbing | Templates generate proven patterns automatically |
| Compliance & audit | Manual checklists, spreadsheets | Validation engine enforces rules at PR time |
| Fear of AI unpredictability | Opaque code suggestions | AI is **optional**; core generation is deterministic |


With ModelHike, the idea is to move programming up a level—
- From the weeds of line-by-line code
- Into the elevated terrain of systems thinking and intent-driven modeling

By giving you a **high-level, declarative DSL** to describe your app, ModelHike restores clarity and flow. You're not babysitting a chaotic AI assistant. You're building a system — with structure, intent, and trust. You're co-creating with AI, not micro-managing it!

And, just like a good hike, you always know where you are.

---

## AI Optional: Exactly Where We Use It
By default, *all* code, docs, and diagrams are produced by version-controlled templates. AI is only used for:

| Area | AI Used? | Notes |
|------|----------|-------|
| Model bootstrapping | Yes | Convert prompts or codebases into initial models |
| Pattern suggestions  | Yes | Recommends templates & best-practices |
| Documentation polish | Yes | Summaries, examples |
| Core code generation  | Yes (prototyping) | Optional during the "let's see" phase; replaced by deterministic templates once you lock the design |

Disable AI at any time:
```yaml
ai:
  enabled: false  # in .modelhikerc or modelhike.yaml
```

### AI Workflow in Practice

1. **Prototype Mode**
  ```bash
  modelhike ai bootstrap           # turn prompt/codebase into initial models
  modelhike ai suggest patterns    # optional: let AI recommend templates
  ```
  Iterate quickly—AI refines models; templates remain editable.

2. **Review & Freeze**
  – Open a PR, review `.dsl.md` + template diffs.  
  – Once satisfied, run:

  ```bash
  modelhike template freeze        # snapshot current templates
  modelhike ai disable             # or set ai.enabled=false
  ```

3. **Deterministic Build**
  ```bash
  modelhike validate && modelhike generate
  ```
  Always yields *identical* outputs for the same commit hash.

4. **Re-enable AI (optional)**
  Need a new module? Flip `ai.enabled=true`, repeat steps 1-2, freeze again.

> Result: AI accelerates the unknowns, but every production build is template-driven, diffable, and CI-safe.

---

## Architecture at a Glance
```mermaid
graph TD
  A[Models (Markdown DSL)] --> B[Model Compiler]
  B --> C[Validation Engine]
  C --> D[Template Engine]
  D --> E[Generated Code, Docs, Diagrams]
```

---

## Hello, Production — Real-World Walkthrough

### Before ModelHike: The Boilerplate Problem
```typescript
// payment-entity.ts
export class Payment {
  id: string;
  amount: number;
  status: string = "NEW";
  customerId: string;
  createdAt: Date;
  updatedAt: Date;
}

// payment-repository.ts
import { Payment } from './payment-entity';
export class PaymentRepository {
  async findById(id: string): Promise<Payment> { /* implementation */ }
  async save(payment: Payment): Promise<Payment> { /* implementation */ }
  async findByCustomerId(customerId: string): Promise<Payment[]> { /* implementation */ }
}

// payment-controller.ts
import { Request, Response } from 'express';
import { PaymentService } from './payment-service';
export class PaymentController {
  constructor(private paymentService: PaymentService) {}
  async createPayment(req: Request, res: Response) { /* validation, mapping, error handling */ }
  async getPaymentById(req: Request, res: Response) { /* validation, mapping, error handling */ }
  async getCustomerPayments(req: Request, res: Response) { /* validation, mapping, error handling */ }
}

// payment-service.ts
import { Payment } from './payment-entity';
import { PaymentRepository } from './payment-repository';
export class PaymentService {
  constructor(private paymentRepository: PaymentRepository) {}
  async createPayment(data: any): Promise<Payment> { /* business logic */ }
  async getPaymentById(id: string): Promise<Payment> { /* business logic */ }
  async getCustomerPayments(customerId: string): Promise<Payment[]> { /* business logic */ }
}

// routes.ts, validation.ts, dto.ts, tests, swagger docs... (30+ files total)
```

### With ModelHike: 1 Model = Complete Microservice

1. **Create a domain model** (`models/payments.dsl.md`):
```modelhike
=== Payments Service ===
++ Payments Module
++ Users Module  # Reference to external model

=== Payments Module ===
Payment
=======
* id        : Id
* amount    : Float (min=0, required)
* customerId: Reference<User>
- status    : Enum = "NEW" | "PENDING" | "COMPLETED" | "FAILED" 
- createdAt : Timestamp = now()
- updatedAt : Timestamp = now()

# APIs ["/payments"]
@ auth:: JWT
@ validation:: strict
@ apis:: create, get-by-id
@ api:: get-customer-payments [GET "/customers/{customerId}/payments"]
#

# Events 
@ publish:: payment.created, payment.status-changed
@ consume:: customer.verified
#
```

2. **Generate complete implementation**
```bash
modelhike generate
```

3. **Result: 30+ consistent, production-ready files**
```
generated/
├─ entities/
│  └─ payment.entity.ts         # Entity with validation
├─ repositories/
│  └─ payment.repository.ts     # Full TypeORM implementation
├─ controllers/
│  └─ payment.controller.ts     # Routes, auth, error handling
├─ services/
│  └─ payment.service.ts        # Business logic layer
├─ dto/
│  └─ payment.dto.ts            # Input/output models
├─ events/
│  ├─ publishers/               # Kafka producers
│  └─ consumers/                # Kafka consumers
├─ tests/
│  ├─ unit/                     # Unit tests
│  └─ integration/              # Integration tests
├─ docs/
│  ├─ api/                      # OpenAPI specs
│  └─ diagrams/                 # C4 architecture diagrams
└─ ... (all wired together with proper dependency injection)
```

---

## Installation & Quick Start
```bash
npm install -g modelhike-cli           # install CLI
modelhike init my-enterprise-app       # scaffold project
cd my-enterprise-app
modelhike generate && npm test         # validate & generate
```

### Project Layout
```
my-enterprise-app/
├─ models/         # Markdown DSL
├─ templates/      # Custom & built-in templates
├─ generated/      # Output: code, docs, diagrams
├─ tests/          # Test suites
├─ modelhike.yaml  # Project config
└─ .modelhikerc    # CLI overrides
```

## GUI Quick-Start (Optional)

If you prefer a visual workflow, ModelHike ships with a VS Code extension (Web client coming soon).

| Task                     | CLI Command                        | VS Code / GUI Path                                |
|--------------------------|------------------------------------|--------------------------------------------------|
| Bootstrap model with AI  | `modelhike ai bootstrap`           | Command Palette ➜ *ModelHike: AI Bootstrap*      |
| Suggest patterns         | `modelhike ai suggest patterns`    | Sidebar ➜ *AI Suggestions*                       |
| Generate artifacts       | `modelhike generate`               | ⏵ Run button in *ModelHike* panel                |
| Validate models          | `modelhike validate`               | Status bar ▸ ✅ icon                              |
| Freeze templates         | `modelhike template freeze`        | Settings ➜ Templates ➜ "Freeze"                  |

<details>
<summary>🎥 2-second tour (click to expand)</summary>

![ModelHike VS Code extension demo](docs/assets/vscode-demo.gif)

**More screenshots**

| DSL Editing with Outline | Automatic C4 Diagram |
|--------------------------|----------------------|
| ![DSL editor](docs/assets/dsl-editor.png) | ![Diagram viewer](docs/assets/diagram-view.png) |

*Template diff viewer*

![Template diff](docs/assets/template-diff.png)

</details>

---

## Extensibility
• **Templates:** Add or override any template under `templates/` – they're just Handlebars / EJS.  
• **Validation Rules:** Write custom rules in TypeScript and reference them in `modelhike.yaml`.  
• **CI/CD:** Run `modelhike validate && modelhike generate` in your pipeline; exit codes are deterministic.

Looking to go deeper? Check out the dedicated guides:  
• [Template Authoring Deep-Dive](docs/template-authoring.md)  
• [Writing Custom Validation Rules](docs/validation-rules.md)

---

## Power Features That Wow

<div style="background-color: #f8f9fa; padding: 15px; border-left: 5px solid #4CAF50; margin-bottom: 20px;">

| Capability | One-liner Demo | Why it matters |
|------------|---------------|----------------|
| **Reverse-Engineer Importer** | `modelhike import --from=typescript ./src` | Bootstrap models from an existing codebase in minutes. |
| **Live Sandbox** | [Try it now](https://codesandbox.io/p/sandbox/modelhike-demo) | No install; shareable link for architecture spikes. |
| **One-Click Supply-Chain Audit** | `modelhike sbom > sbom.json`  
`modelhike attest --slsa` | Generates an SBOM (Software Bill of Materials) and SLSA provenance—ideal for security reviews without drowning you in jargon. |
| **Language-Agnostic Generation** | `templates: [go-clean, typescript-clean]` | Swap templates to output Go, Java, or TS from the same model. |
| **ADR Scaffold** | `modelhike adr new "Messaging vs REST"` | Keeps architectural decisions versioned next to code. |
| **Zero-Boilerplate Tests** | `modelhike generate --tests` | Auto-generated contract/snapshot tests keep APIs honest. |

</div>

---

## ADR Scaffold (Architecture Decision Records)

<div style="background-color: #e6f7ff; padding: 15px; border-left: 5px solid #1890ff; margin-bottom: 20px;">

> 💡 **ADR decisions drive generation:** choose Kafka in an ADR and `modelhike generate` will scaffold Kafka producers/consumers automatically.

Keep architectural reasoning version-controlled right next to your code and models.

```bash
modelhike adr new "Messaging vs REST"
```

<details>
<summary>Generated template</summary>

```md
# ADR-2024-07-20: Messaging vs REST

## Context
<!-- Why is this decision needed? -->

## Decision
<!-- The choice made. -->

## Consequences
<!-- Positive, negative, neutral outcomes. -->
```

</details>

Benefits:
* **Team alignment:** decisions are peer-reviewed via normal PRs.
* **Easy discovery:** ADRs live under `docs/adr/`; link from code or models.
* **Governance-ready:** comply with ISO/PCI/SOX "documented architecture decisions" requirements.
* **Executable decisions:** Generate code that reflects recorded ADRs—e.g., mark "Kafka" in an ADR and messaging scaffolds will auto-wire Kafka producers/consumers instead of REST or RabbitMQ.

</div>

---

## Security & Privacy

<div style="background-color: #fff3e0; padding: 15px; border-left: 5px solid #ff9800; margin-bottom: 20px;">

> 🔒 **No surprises:** Data stays in your repo; optional AI calls respect org policies.

- No model data leaves your network by default.  
- AI calls are disabled automatically in CI unless explicitly enabled.  
- Generated code is MIT licensed—no copyleft risk.  
- Produce SBOM & provenance with `modelhike sbom` / `attest --slsa`.  
- See `SECURITY.md` for threat model & SBOM.

</div>

---

## Zero-Boilerplate Tests

<details open>
<summary>Overview</summary>

ModelHike can auto-generate contract & snapshot tests for every scaffolded API or event, giving you continuous assurance that the generated services remain faithful to their models.

```bash
modelhike generate --tests          # Jest/Vitest (TypeScript) or Go-test suites
npm test                             # all green out-of-the-box
```

Why it rocks:
* **Drift protection:** fails CI if someone hand-edits generated code without updating the model.
* **Living documentation:** specs double as up-to-date examples for new joiners.
* **Baseline extension:** drop custom tests next to generated ones—never start from scratch.

</details>

<details>
<summary>Example generated test (click to view)</summary>

```ts
// generated/tests/payment-service.contract.spec.ts
it('POST /payments should create a payment', async () => {
  const res = await request(app).post('/payments').send({ amount: 42.0 });
  expect(res.status).toBe(201);
  expect(res.body).toMatchSchema('Payment');
});
```
</details>

---

## System Requirements
| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU      | 2 cores | 4+ cores    |
| RAM      | 4 GB    | 8+ GB       |
| Node.js  | v18 LTS | v20 LTS     |

---

## Troubleshooting
| Issue | Command |
|-------|---------|
| Validate models & config | `modelhike validate` |
| Regenerate artifacts     | `modelhike generate` |
| Health check             | `modelhike doctor`   |
| Template errors          | `modelhike template validate` |

---

## Glossary
| Term | Definition |
|------|------------|
| **Declarative Apps** | Systems described via high-level models, letting templates generate implementation boilerplate |
| **AI-in-Loop** | Optional assistive AI features, never mandatory |
| **DSL** | Domain-Specific Language; here, a Markdown syntax for architectural models |
| **Deterministic Generation** | Running the same inputs and templates always yields identical outputs |
| **Template Engine** | Renders code/docs/diagrams from the compiled model |
| **Validation Engine** | Static & semantic checks ensuring models comply with rules |

---

## FAQ / Further Reading
- [Advanced Modeling Patterns](TBD#)
- [Migration Guide](TBD#)
- [Architecture Decision Records](#)
- [Community & Support](TBD#)

---

## Ranger Station

Need help or want to contribute?

- [Join the Discussions](TBD)
- [Open an Issue](TBD)
- [Contribute a Plugin](TBD)

ModelHike is open source and welcomes fellow explorers.

------

## Ready to Hike?

Feel the flow, spark creativity, enjoy the journey, and build your Mega App —- one joyful step at a time. 🚀

- [Project Roadmap](TBD)
- [Contribution Guide](TBD)
- [Design Philosophy](TBD)

See you on the trail. 🏜️

----

** We're building ModelHike to be the most joyful, intuitive, and structured way to develop modern software, in the era of AI.**

> **Built by engineers, for engineers.** Stop fighting boilerplate and drift—describe your architecture once, generate confidently forever.
