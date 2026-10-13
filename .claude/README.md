# .claude

Sub-agent definitions and shared skills for this repository. See `CLAUDE.md` at the repo root for the project constitution and sprintkit workflow.

## Security scanners (security-auditor agent)

The `security-auditor` agent (`.claude/agents/security-auditor.md`) runs deterministic scanners before semantic review, when they're installed. None are required — a missing scanner is noted in the audit report's "Not checked" section and the agent falls back to manual review for that pass instead of skipping it or installing anything itself (it never provisions tools).

Install any or all of these locally to get full scanner coverage:

```bash
# macOS (Homebrew)
brew install semgrep trivy checkov gitleaks syft grype
```

```bash
# Linux / manual
pip install semgrep checkov
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

| Scanner | Checks |
|---|---|
| `semgrep` | Application code SAST (injection, insecure patterns) |
| `trivy` | Containers, filesystem, IaC misconfiguration, known-vulnerability scanning |
| `checkov` | Terraform/CloudFormation/Kubernetes/Bicep misconfiguration |
| `gitleaks` | Secrets committed to the repo or its history |
| `syft` | SBOM generation for a dependency tree |
| `grype` | Known-vulnerability matching against an SBOM or image |

Verify what's installed:

```bash
for t in semgrep trivy checkov gitleaks syft grype; do command -v "$t" >/dev/null && echo "$t: installed" || echo "$t: not found"; done
```
