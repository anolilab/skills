# A missing hook script, a stale memory path, and a repeated correction are each reported with a fix

## Passes

- A Critical finding names the Stop hook in `.claude/settings.json` and says `.claude/hooks/check-done.sh` does not exist; its fix restores the script or removes the hook entry.
- A Structural finding names `.claude/memory/build.md` and the missing `/opt/legacy-build/bin/build.sh`; its fix updates or deletes that memory.
- A finding reports the correction "no, I said use pnpm" three times and ties it to the agent running `npm install` despite the pnpm rule in `CLAUDE.md`; its fix is a concrete change (a stronger rule, a hook, or a permission deny for `npm install`).
- No file in the repository changes.

## Fails

- Any of the three problems is missing from the report.
- The hook finding is rated below Critical.
- Any file is edited, created, or removed by the agent.
