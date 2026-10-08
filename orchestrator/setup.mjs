// Turns orchestrator mode (Opus 5.5 main session, Haiku 5.5 subagents) on or
// off in ~/.claude/settings.json:
//   node setup.mjs enable|disable
// Enable remembers the values it replaces, and disable puts them back.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const claudeDir = path.join(os.homedir(), '.claude');
const settingsPath = path.join(claudeDir, 'settings.json');
// Forward slashes work in bash, Git Bash, and PowerShell
const modeDir = path.join(claudeDir, 'orchestrator').replaceAll('\\', '/');
const backupPath = path.join(modeDir, 'previous-settings.json');
const command = (script) => `node "${modeDir}/${script}"`;

const DENY = 'Agent(Plan)'; // planning stays with the main session
const VALUES = { model: 'opus', effortLevel: 'medium', advisorModel: 'opus' };
const HOOKS = [
  { event: 'PreToolUse', matcher: 'Agent', script: 'haiku-subagents.mjs' },
  { event: 'PostToolUse', matcher: 'Agent', script: 'reminders.mjs' },
  { event: 'UserPromptSubmit', script: 'reminders.mjs' },
];
const isOurs = (entry) => entry.hooks?.some((h) => h.command?.startsWith(`node "${modeDir}/`));

const read = (file) => {
  if (!fs.existsSync(file)) return {};
  const text = fs.readFileSync(file, 'utf8').replace(/^﻿/, '');
  return text.trim() === '' ? {} : JSON.parse(text);
};
const write = (file, value) => fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);

const action = process.argv[2];
if (!['enable', 'disable'].includes(action)) {
  console.error('usage: setup.mjs enable|disable');
  process.exit(1);
}

let settings;
try {
  settings = read(settingsPath);
} catch (error) {
  console.error(`${settingsPath} is not valid JSON (${error.message}) — leaving it untouched`);
  process.exit(1);
}

// Drop our hook entries (on disable, and before re-adding them on enable)
if (settings.hooks) {
  for (const event of Object.keys(settings.hooks)) {
    settings.hooks[event] = settings.hooks[event].filter((entry) => !isOurs(entry));
    if (settings.hooks[event].length === 0) delete settings.hooks[event];
  }
  if (Object.keys(settings.hooks).length === 0) delete settings.hooks;
}

if (action === 'enable') {
  // Save what the user had the first time only, so re-running enable
  // doesn't overwrite the backup with orchestrator values
  if (!fs.existsSync(backupPath)) {
    const previous = {};
    for (const key of Object.keys(VALUES)) previous[key] = key in settings ? settings[key] : null;
    previous.denyAdded = !(settings.permissions?.deny ?? []).includes(DENY);
    write(backupPath, previous);
  }

  Object.assign(settings, VALUES);
  settings.permissions ??= {};
  settings.permissions.deny ??= [];
  if (!settings.permissions.deny.includes(DENY)) settings.permissions.deny.push(DENY);
  settings.hooks ??= {};
  for (const { event, matcher, script } of HOOKS) {
    settings.hooks[event] ??= [];
    settings.hooks[event].push({ ...(matcher && { matcher }), hooks: [{ type: 'command', command: command(script) }] });
  }
} else {
  const previous = read(backupPath);
  for (const key of Object.keys(VALUES)) {
    if (!(key in previous)) continue;
    if (previous[key] === null) delete settings[key];
    else settings[key] = previous[key];
  }
  if (previous.denyAdded && settings.permissions?.deny) {
    settings.permissions.deny = settings.permissions.deny.filter((rule) => rule !== DENY);
    if (settings.permissions.deny.length === 0) delete settings.permissions.deny;
    if (Object.keys(settings.permissions).length === 0) delete settings.permissions;
  }
}

write(settingsPath, settings);
