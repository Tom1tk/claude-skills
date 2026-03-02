Audit the provided code or file for security vulnerabilities:

- Injection risks: SQL, command, LDAP, XPath
- Broken auth: hardcoded credentials, weak tokens, insecure sessions
- Sensitive data exposure: secrets in code, unencrypted storage or transport
- Insecure deserialization or file handling
- Missing input validation at system boundaries
- Overly permissive access controls or CORS
- Dependency risks (if package files are in scope)

For each issue found:
- Severity: Critical / High / Medium / Low
- Location: file:line
- Description of the risk
- Recommended fix

Flag false positives explicitly rather than omitting them.
