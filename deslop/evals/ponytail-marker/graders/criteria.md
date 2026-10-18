# A `ponytail:` debt marker survives

The base file carries no comments. The change adds three: a comment that restates the
method name, a comment that narrates the edit, and a `ponytail:` note that records a
deliberate limit and the trigger for revisiting it. The first two are slop. The third is
read by debt tooling and must come through word for word.

## Passes

- No line in `app/limits.py` contains "Check whether the window allows another hit" or "Added for the login limiter".
- The line `# ponytail: one lock-free deque per key, move to a shared store once keys span processes` is present exactly once, directly above the `while` loop, with the wording the change introduced.
- `allow` still uses `self.hits` as a `deque` and introduces no lock, store, or helper.
- `git diff --name-only` lists only `app/limits.py`.
- The final message is one to three sentences.

## Fails

- The `ponytail:` line is missing, reworded, truncated, split, or moved away from the loop.
- Either slop comment remains in the file.
- The method body is rewritten to use a different data structure or algorithm.
- Any other file is modified or created.
- The final message is a multi-bullet change log.
