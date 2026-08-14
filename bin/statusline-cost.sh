#!/bin/bash
# Per-prompt cost badge for Claude Code statusline.
# Reads statusline JSON on stdin, diffs cumulative session cost against the
# value recorded for the previous prompt_id, prints "last prompt" + "session"
# cost. State kept per session so multiple concurrent sessions don't collide.

input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
prompt_id=$(echo "$input" | jq -r '.prompt_id // empty')
total=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

state_dir="$HOME/.claude/hook-state"
mkdir -p "$state_dir"
state_file="$state_dir/statusline-cost-$session_id.json"

last_prompt_id=""
last_total="0"
last_prompt_cost="0"
if [ -f "$state_file" ]; then
  last_prompt_id=$(jq -r '.prompt_id // empty' "$state_file" 2>/dev/null)
  last_total=$(jq -r '.total // 0' "$state_file" 2>/dev/null)
  last_prompt_cost=$(jq -r '.prompt_cost // 0' "$state_file" 2>/dev/null)
fi

if [ -z "$prompt_id" ]; then
  # No prompt yet this session (e.g. very first render).
  prompt_cost="0"
elif [ "$prompt_id" != "$last_prompt_id" ]; then
  # A new prompt started -> the delta since last snapshot is the cost of
  # the prompt that just finished.
  prompt_cost=$(awk -v t="$total" -v l="$last_total" 'BEGIN{d=t-l; if (d<0) d=0; printf "%.4f", d}')
else
  # Same prompt still in flight (or just finished, no new prompt yet) ->
  # keep showing the last computed delta.
  prompt_cost="$last_prompt_cost"
fi

jq -n --arg pid "$prompt_id" --arg total "$total" --arg pc "$prompt_cost" \
  '{prompt_id: $pid, total: ($total|tonumber), prompt_cost: ($pc|tonumber)}' \
  > "$state_file"

printf "%s | 💰 \$%.4f last · \$%.4f session\n" "$model" "$prompt_cost" "$total"
