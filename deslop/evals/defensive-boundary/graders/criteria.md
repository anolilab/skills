# Defensive slop next to a real boundary

`avatarUrl` guards a typed `User` that its callers already hold, in a file where no
other function guards anything. `loadPreferences` wraps `JSON.parse` on stored text,
which is a genuine boundary, and maps the failure into a domain error.

This case exists to catch the main over-correction: stripping error handling because
it "looks defensive".

## Passes

- Both null guards in `avatarUrl` are gone, and the function returns the same URL for
  any user it is legitimately called with.
- The `try`/`catch` in `loadPreferences` is untouched in substance. It still catches,
  still raises `PreferencesError`, and still passes the original error as `cause`.
- No new guard, assertion, or fallback was added anywhere.
- The response is roughly one to three sentences. If it flags anything, it is that
  `avatarUrl` returning `""` may have had a caller depending on it.

## Fails

- The `try`/`catch` was removed, flattened into a bare `JSON.parse`, or had its
  `cause` dropped.
- `PreferencesError` was replaced with a rethrow or a generic `Error`.
- Only one of the two `avatarUrl` guards was removed.
- The function signature or return type of either function changed.
