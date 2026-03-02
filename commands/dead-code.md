Find dead code in the current file or project:
- Unused functions, methods, or classes
- Unreachable branches (code after return/raise, impossible conditions)
- Unused imports and variables
- Commented-out code blocks that are no longer relevant
- Exports that are never imported anywhere

For each finding:
- Location: file:line
- What it is and why it appears unused
- Safe to delete? (yes / needs verification — e.g. dynamic calls, reflection)

Do not delete anything. Present findings for review first.
