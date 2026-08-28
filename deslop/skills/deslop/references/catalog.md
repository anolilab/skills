# Slop catalog

Every entry is **Slop** (delete or rewrite) versus **Not slop** (leave it). When a case
falls between the two, the tiebreaker is always the surrounding file: match it.

## Contents

1. Comment slop: restating code, narrating the edit, section banners, invented TODOs
2. Defensive slop: guards, `try`/`catch`, and fallbacks for cases that cannot happen
3. Type-evasion slop: `any`, `unknown`, chained casts, suppression pragmas
4. Control-flow slop: needless nesting, redundant conditionals, one-use intermediates
5. Abstraction slop: single-use helpers, wrappers, speculative generality, naming
6. Duplication and dead code: both paths kept, shims for unshipped code, orphans
7. Test slop: over-mocking, assertions on the mock, tautologies, bloated fixtures
8. Prose slop: marketing voice, emoji headers, unrequested README and changelog edits
9. Structural slop: misplaced files, unneeded configs and dependencies
10. Language notes: TypeScript/JavaScript, Python, Go, Rust, Shell, SQL

---

## 1. Comment slop

### Slop

**Restating the code.** The comment carries no information the line does not.

```ts
// Increment the counter
counter += 1;

// Loop through the users
for (const user of users) {
```

**Narrating the edit.** Comments addressed to the reviewer, not to the next reader.
These date instantly, and they are the loudest tell in the list.

```ts
// Updated to handle the new format
// Note: changed from the previous implementation
// This is now more robust
// Added error handling here
```

**Section banners** in a file that has none.

```py
# ============================================
# HELPER FUNCTIONS
# ============================================
```

**Docstrings that restate the signature** in a codebase that does not document
internal helpers.

```py
def get_user_by_id(user_id: str) -> User:
    """Get a user by ID.

    Args:
        user_id: The ID of the user.

    Returns:
        The user.
    """
```

**Obsolete TODOs** the agent invented for work it had no intention of doing
(`// TODO: add tests`, `// TODO: handle edge cases`).

**Type information in a comment** where the type is already declared.

### Not slop

- Why, not what: `// The vendor API returns 200 with an error body, so status is not enough.`
- A `SAFETY:` / `INVARIANT:` note justifying a cast, a lock ordering, or an unsafe block.
- Links to an issue, RFC, spec section, or upstream bug.
- Public API documentation in a codebase that documents its public API.
- A TODO with an owner or ticket reference.

### Calibration

Count comments per hundred lines in the untouched parts of the file. If the file has
two and the diff adds fifteen, thirteen of them are slop.

---

## 2. Defensive slop

The agent could not prove a value was safe, so it guarded. In a codebase with real
boundaries, that guard belongs at the boundary and nowhere else.

### Slop

**Guarding a caller you control.** Every other function in the module trusts its input;
this one does not.

```ts
function formatName(user: User): string {
  if (!user) return "";           // `user: User`, so this cannot be null here
  if (!user.name) return "";
  return user.name.trim();
}
```

**Blanket `try`/`catch` around code that does not throw**, especially one that swallows
or merely logs.

```ts
try {
  const total = items.reduce((sum, i) => sum + i.price, 0);
  return total;
} catch (error) {
  console.error("Error calculating total:", error);
  return 0;                        // invents a wrong answer
}
```

**Fallback values that mask failure.** `?? {}`, `|| []`, `?? "unknown"` applied where the
absent case is a bug, not a state. The empty default flows onward and the real error
surfaces three layers away.

**Re-validating what a validated boundary already checked.** If the request was parsed by
a schema at the edge, the handler does not re-check the fields.

**Optional chaining on non-optional types**: `user?.id` where `user: User`.

**`hasOwnProperty` / `in` checks** on an object literal the same function just built.

**Empty catch with an apologetic comment.**

```js
} catch (e) {
  // Ignore errors
}
```

### Not slop

- Anything at a genuine boundary: HTTP, filesystem, database, subprocess, `JSON.parse`,
  environment variables, user input, third-party SDK calls.
- A `catch` that translates an error into a domain type or adds context and rethrows.
- Guards required by the type system to narrow. Those are not defensive, they are proof.
- Defensive style that the surrounding module uses consistently. Match it.
- Assertions and invariant checks that crash loudly. Those are the opposite of slop.

---

## 3. Type-evasion slop

The type system objected and the agent silenced it. Each of these fabricates evidence
that the code never established.

### Slop

**`any` as an escape hatch**, in a codebase that does not otherwise use it.

```ts
const result = (response as any).data.items;
```

**Chained assertions**: laundering a value through `unknown` or `object` to reach an
unrelated type. Two casts in a row are never justified by one fact.

```ts
const user = payload as unknown as User;
const config = input as object as Config;
```

**Widen, then assert back.** The value's type was known; the code discarded that
knowledge and then claimed it again.

```ts
const loaded: User = loadUser();
const stored: unknown = loaded;
const user = stored as User;
```

**`unknown` in a contract**, as a parameter type or a return type. It pushes the
narrowing onto every caller. (The `cause` property on errors is the conventional
exception.)

```ts
function handle(input: unknown) {}
function loadUser(): Promise<unknown> {}
type ExternalValue = unknown;      // an alias that only conceals `unknown`
```

**Unsafe dictionary contracts**: `Record<string, unknown>`, `{ [k: string]: any }`,
`Record<string, object>`. Parse into a real type at the boundary instead.

**Non-null assertions to quiet the compiler**: `value!.field` where nothing established
non-nullness.

**Suppression pragmas without a reason**: `@ts-ignore`, `@ts-expect-error`,
`# type: ignore`, `//nolint`, `#[allow(...)]`, `// eslint-disable-next-line` with no
explanation of why the rule is wrong here.

**Ad hoc `typeof` narrowing** scattered through business logic where the project parses
at its boundaries.

```ts
if (typeof input === "string") { useName(input); }
```

**Conditional empty-object spreads** to omit a field.

```ts
const options = { ...(timeout !== undefined ? { timeout } : {}) };
```

**Broad `object` parameters**: `function save(value: object)`.

**Losing inference to an explicit broad annotation.** The annotation discards the known keys:

```ts
const handlers: Record<string, Handler> = { start: startHandler };
// prefer inference, or `satisfies Record<string, Handler>`
```

### Not slop

- A cast with a specific `SAFETY:` comment naming the invariant that was checked.
- `unknown` as the *input* to a parser or type guard whose output is a real type. That
  is the boundary doing its job.
- `any` where the project already uses it in comparable positions, or where an untyped
  third-party module leaves no alternative and the file says so.
- `as const`.
- Generic constraints and variance annotations that look noisy but are load-bearing.

### The fix

Do not simply delete a cast and leave a type error. Either parse the value into the
type at the boundary, narrow it properly, or, when neither is in scope, keep the cast
and add the `SAFETY:` comment stating what makes it true. Report it if you could not
resolve it.

---

## 4. Control-flow slop

### Slop

**Nesting where the file uses early returns** (or the reverse; match the file).

```ts
function process(order: Order) {
  if (order.isValid) {
    if (order.items.length > 0) {
      if (order.payment) {
        return submit(order);
      }
    }
  }
}
```

**`else` after `return`.**

**Redundant boolean work**: `x === true`, `cond ? true : false`, `if (a) return true; else return false;`.

**A switch or if-chain with a defensive `default` that cannot be reached** on an
exhaustive union, unless the project's convention is an exhaustiveness assertion, which
is the good version.

**Intermediate variables used exactly once**, named after the expression rather than the
concept: `const userDataResult = ...; return userDataResult;`

**Redundant `await`-in-loop** where the file uses `Promise.all` elsewhere. (Only when the
iterations are genuinely independent, since sequencing is often deliberate.)

### Not slop

- Nesting that mirrors real domain structure.
- A `default` branch that throws on an unexpected runtime value from outside the program.
- Named intermediates that make a dense expression readable. That is a style the file
  either has or does not.

---

## 5. Abstraction slop

Agents reach for structure early. A structure with only one user has not earned its place yet.

### Slop

**Single-use helpers** extracted from a function that reads fine inline, especially when
the helper sits directly above its only caller.

**Wrappers that add nothing.**

```ts
function getUserName(user: User): string {
  return user.name;
}
```

**Options objects for one or two parameters** in a codebase of positional arguments.

**Interfaces with one implementation and no test double**, invented for a seam nobody asked for.

**Speculative generality**: a type parameter, a strategy map, or a plugin hook for the
one case that exists.

**`Shape`, `Data`, `Info`, `Manager`, `Helper`, `Util`, `Handler` suffixes** where the
domain has a real word. `UserShape` is `User`.

**Barrel `index.ts` re-exports** created for a two-file directory in a repo that imports
by path.

**Constants files** holding one string used once.

**Config knobs nobody requested**: a parameter defaulted to today's behaviour, added
"for flexibility".

### Not slop

- An extraction with two or more genuine call sites.
- An interface that exists because a test or a second adapter implements it.
- A named constant replacing a value repeated three times, or a magic number given a name.
- Structure the project's architecture already mandates (ports/adapters, layers, a
  module boundary the docs describe).

---

## 6. Duplication and dead code

### Slop

**Both paths kept.** The new implementation lands and the old one is left behind
"for reference" or behind a flag nobody will flip.

**Backwards-compatibility shims for code that never shipped.** If the old signature only
ever existed on this branch, there is nothing to be compatible with. Delete the shim and
update the call sites.

**Deprecation markers on brand-new code.**

**Copy-paste variants**: three near-identical functions differing in one literal.

**Unused exports, imports, parameters, and variables** the diff introduced.

**Orphaned files**: a module nothing imports, a script nothing calls, a fixture nothing
loads.

**Commented-out code.** Version control already has it.

### Not slop

- A genuine deprecation path for an API that has real external consumers.
- Duplication the project deliberately tolerates across module boundaries to avoid
  coupling. Check whether a shared helper would cross a layer the architecture forbids.
- Exports consumed by tests, tooling, or a public entry point. Grep before deleting.

---

## 7. Test slop

### Slop

**Module mocking that replaces the thing under test's real seams.**

```ts
vi.mock("./user-store");
```

Prefer a real in-memory implementation or dependency injection. A test whose subject is
entirely mocked asserts only that the mock was configured.

**Asserting on the mock**: `expect(mockFn).toHaveBeenCalledWith(...)` as the *only*
assertion, with no check on the observable result.

**Tautologies**: `expect(true).toBe(true)`, `expect(result).toBeDefined()` as the sole
assertion, a test that recomputes the implementation and compares it to itself.

**Tests that restate the implementation line by line** rather than pinning behaviour.

**Snapshot tests added for logic** that a real assertion would express better.

**Bloated arrange blocks**: a fifty-line fixture where four fields matter.

**`describe` nesting three deep** in a suite that is otherwise flat.

**Skipped or `.only` tests** left in the diff.

### Not slop

- Mocking a genuine external dependency: network, clock, randomness, filesystem, payment
  provider.
- Verbose but meaningful table-driven cases.
- A snapshot pinning a serialised output format, which is exactly what snapshots are for.
- Setup that is long because the domain object genuinely is.

---

## 8. Prose slop

Applies to README, docs, comments-as-docs, PR descriptions, and commit messages in the diff.

### Slop

- Marketing voice: "comprehensive", "robust", "seamless", "powerful", "production-ready",
  "best-in-class", "enterprise-grade".
- Emoji section headers, ✅/❌ tables, and celebratory summaries in technical docs that
  use none.
- A README rewritten when the ask was a code change.
- A CHANGELOG entry nobody requested, or one written in release-notes voice for an
  internal change.
- The rule-of-three cadence: every list padded to exactly three items, every sentence
  built from three clauses.
- Restating the diff as documentation: "This PR adds a new function that..."
- Summary sections at the bottom of a doc that repeat the doc.

### Not slop

- Docs the project's own conventions require for this kind of change.
- A changelog entry when the repo has a changelog policy.
- Plain description of externally visible behaviour, defaults, and failure modes.

---

## 9. Structural slop

### Slop

- New files placed where the project does not put that kind of file, such as a `utils/` folder
  in a repo organised by feature, a test beside the source in a repo with a `tests/` tree.
- New config files (`.editorconfig`, `.prettierrc`, a second tsconfig) the task never
  needed.
- A dependency added for something the standard library or an existing dependency already
  does. Check `package.json` / `pyproject.toml` / `go.mod` before assuming it is new.
- Scripts, Dockerfiles, or CI jobs invented as scaffolding around the actual change.
- `.env.example` entries for variables the code does not read.

### Not slop

Anything the task genuinely required, and anything the project's layout documents.

---

## 10. Language notes

**TypeScript / JavaScript**: the type-evasion section is where most of it lives. Also
watch for `Promise` chains in an `async`/`await` codebase, `require` in ESM, default
exports in a named-export project, and `React.FC` in a codebase that annotates props
directly.

**Python**: imports inside functions instead of at the top of the module (the tell is
almost always slop; the exception is a genuine circular-import or lazy-load workaround,
which deserves a comment saying so). Also: `except Exception` swallowing everything,
`Any` from `typing` used as an escape hatch, mutable default arguments, docstrings on
private helpers in a codebase that does not use them, and `if __name__ == "__main__"`
blocks bolted onto library modules.

**Go**: `if err != nil { return err }` without wrapping context in a codebase that wraps;
`interface{}` / `any` parameters; interfaces declared next to their implementation rather
than at the consumer; a `context.Context` threaded through functions that never use it.

**Rust**: `.unwrap()` / `.expect()` in library code that otherwise returns `Result`;
`.clone()` sprinkled to defeat the borrow checker; `#[allow(dead_code)]` on new code;
`Box<dyn Error>` where the crate has a real error enum.

**Shell**: `set -euo pipefail` added to a script collection that has none (or missing
where every sibling has it); `|| true` swallowing failures; useless `cat`.

**SQL / migrations**: a rollback that does not roll back; defensive `IF NOT EXISTS` on
a fresh migration in a project that does not use it.
