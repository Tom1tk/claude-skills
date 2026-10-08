// PreToolUse hook for the Agent tool: runs every subagent on Haiku 5.5 at
// xhigh effort, whatever model or effort the main session asked for.
import fs from 'node:fs';

const event = JSON.parse(fs.readFileSync(0, 'utf8'));

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    permissionDecision: 'allow',
    updatedInput: { ...event.tool_input, model: 'haiku', effort: 'xhigh' },
  },
}));
