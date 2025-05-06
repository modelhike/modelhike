# Security Policy

ModelHike takes supply-chain, data-privacy, and runtime security seriously. This document explains how we keep you safe and how **you** can report issues.

---

## Supported Versions

| Version | Supported | Security Fixes |
|---------|-----------|----------------|
| `main`  | ✅        | Yes            |
| `0.5`   | ✅        | Yes            |
| `<0.5`  | ❌        | No             |

---

## Reporting a Vulnerability

If you discover a vulnerability in the CLI, templates, or generated artifacts:

1. **Do not open a public issue.**  
2. Email **security@modelhike.dev** with a detailed description and PoC.  
3. We will acknowledge within **24 h** and provide a remediation timeline.

Credit will be given in release notes unless you request anonymity.

---

## Threat Model

| Layer | Risks Mitigated | Controls |
|-------|-----------------|----------|
| **CLI Execution** | Command injection, path traversal | All file writes confined to configured project root; validated paths. |
| **Template Rendering** | Sandbox escape, prototype pollution | Sandboxed Handlebars/EJS engine with helper whitelist. |
| **AI Integrations** | Data exfiltration, prompt injection | AI disabled by default in CI; outbound calls can be routed via proxy or blocked. |
| **Generated Code** | Insecure defaults | Templates pass ESLint/SAST; unit tests generated via `--tests`. |
| **Supply-Chain** | Dependency tampering | Lockfiles, checksum verification, SBOM + SLSA.

---

## Supply-Chain Assurance

### SBOM
Run:
```bash
modelhike sbom > sbom.json
```
Generates a **CycloneDX v1.4** SBOM listing all runtime and buildtime deps.

### SLSA Provenance
```bash
modelhike attest --slsa
```
Produces a signed provenance statement suitable for SLSA Level 2 pipelines.

---

## Data Privacy

ModelHike CLI operates **offline by default**. When optional AI features are enabled:

* Only the model snippets you choose are sent to the LLM provider.  
* No sourcecode or secrets are transmitted.  
* You can self-host the inference endpoint via `MODELHIKE_AI_ENDPOINT`.

---

## Runtime Hardening Recommendations

1. Run `modelhike validate` in CI to prevent malformed models.  
2. Commit generated artifacts so production builds are diffable.  
3. Pin template versions in `modelhike.yaml` to avoid drift.  
4. Use `npm audit` / `govulncheck` on generated projects.

---

## Contact

Email: **security@modelhike.dev**  
PGP: `0xBEEF DEAD C0DE CAFE`

We appreciate responsible disclosure and will work with you to keep the community safe. 