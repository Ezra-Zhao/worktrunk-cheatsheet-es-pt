#!/usr/bin/env bash
# parallel-agents.sh - start three coding agents, one Worktrunk worktree each.
#
# Usage:
#   1. Install Worktrunk and the shell integration first:
#        brew install worktrunk && wt config shell install
#   2. Run this script from inside the git repo you want to split up:
#        bash examples/parallel-agents.sh
#   3. Check on everyone with:  wt list
#      Clean a finished station with:  wt switch <branch> && wt remove
#
# Swap the agent: set AGENT=codex (default is claude) before running:
#   AGENT=codex bash examples/parallel-agents.sh
set -euo pipefail

AGENT="${AGENT:-claude}"

command -v wt >/dev/null 2>&1 || {
  echo "wt not found. On Windows the binary is named git-wt - see the install card in README.md." >&2
  exit 1
}
command -v "$AGENT" >/dev/null 2>&1 || {
  echo "agent command '$AGENT' not found in PATH." >&2
  exit 1
}
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Run this from inside a git repository." >&2
  exit 1
}

# One line per station: <branch> -- <task for the agent>.
# The text after -- is passed through to the agent command by -x.
wt switch -x "$AGENT" -c feature-a -- 'Add user authentication'
wt switch -x "$AGENT" -c feature-b -- 'Fix the pagination bug'
wt switch -x "$AGENT" -c feature-c -- 'Write tests for the API'

wt list
