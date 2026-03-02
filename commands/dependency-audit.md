Audit project dependencies for risk:
1. Identify the dependency manifest (package.json, requirements.txt, pyproject.toml, go.mod, etc.)
2. Check for:
   - Known vulnerabilities (CVEs) — reference NVD/OSV/GitHub Advisory where possible
   - Outdated packages with security-relevant changelogs
   - Packages with no recent maintenance activity (abandoned)
   - Overly broad version pins that allow unsafe upgrades
   - Unused dependencies that increase attack surface

Output a prioritised list:
- Package name + current version
- Issue type and severity
- Recommended action (update, replace, remove, pin)

Note: this is a static analysis. Run `npm audit`, `pip-audit`, or `trivy` for live CVE data.
