# cost-statusline

Claude Code statusline badge showing **per-prompt cost** and **cumulative session cost**, in USD.

```
Sonnet 5 | 💰 $0.0700 last · $0.1200 session
```

No API calls, no pricing table to maintain — it reads `cost.total_cost_usd` that
Claude Code already computes per session, and diffs it across `prompt_id`
changes to isolate the cost of the prompt that just finished.

## Install

```
/plugin marketplace add <owner>/cost-statusline
/plugin install cost-statusline@cost-statusline-marketplace
```

(Replace `<owner>/cost-statusline` with wherever this repo ends up — a GitHub
`owner/repo` slug, or a local path for testing: `/plugin marketplace add ./cost-statusline`.)

**One manual step is unavoidable:** Claude Code does not load a `statusLine`
key from a plugin's own settings — you point your own `~/.claude/settings.json`
at the script once, after installing:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"${CLAUDE_PLUGIN_ROOT}/bin/statusline-cost.sh\""
  }
}
```

If you already have a `statusLine` configured (e.g. another plugin's badge),
you'll need to combine the two scripts or chain their output — Claude Code
only runs one `statusLine` command.

## Uninstall

```
/plugin uninstall cost-statusline@cost-statusline-marketplace
```

Then remove the `statusLine` block from `~/.claude/settings.json` (or restore
whatever it pointed at before).

## How it works

Every statusline render, Claude Code passes JSON on stdin including
`session_id`, `prompt_id`, and `cost.total_cost_usd` (cumulative). The script
keeps one small state file per session under `~/.claude/hook-state/`, and
whenever `prompt_id` changes it records `total_cost_usd(now) − total_cost_usd(at
previous prompt)` as the finished prompt's cost. That figure is displayed
until the next prompt completes.
