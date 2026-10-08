// Short, well-timed nudges for orchestrator mode: a delegation reminder with
// each prompt, and an audit reminder each time a subagent returns.
import fs from 'node:fs';

const event = JSON.parse(fs.readFileSync(0, 'utf8'));

const text = {
  UserPromptSubmit: 'Orchestrator mode: do planning, creative and design work yourself; delegate scoped work (finding and reading code, mechanical edits, tests, builds) to subagents with self-contained briefs.',
  PostToolUse: 'That subagent result is unverified. Check the diff, files, or test output before relying on it or reporting it as done.',
}[event.hook_event_name];

if (text) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: event.hook_event_name, additionalContext: text },
  }));
}
