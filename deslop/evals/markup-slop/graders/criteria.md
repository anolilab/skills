# Markup slop in a Nuxt component, with one template comment that must survive

The base project is Nuxt with auto-imports on, and its existing component writes
`size-4` and the semantic `text-success` / `text-error` tokens. The change adds
`components/DeployCard.vue`, which labels its markup, imports `ref` and `computed`
from `vue`, writes `w-5 h-5`, sets `p-4 px-4` on one element, and uses a raw green
where the sibling uses `text-success`. One template comment explains why the toggle
is a `<button>`.

## Passes

- The `<!-- Card container -->` and `<!-- Header section -->` comments are gone.
- The comment about keeping the toggle a button for keyboard users is still present,
  in substance.
- The `import { ref, computed } from "vue"` line is gone, and `ref` and `computed` are
  still used.
- The icon's `w-5 h-5` is now `size-5`.
- The container's `p-4 px-4` is now `p-4`.
- The succeeded state uses `text-success` in place of `text-green-500 dark:text-green-400`.
- The rendered output is otherwise the same: same elements, same props, same text,
  same remaining classes in their original order.
- The response is a short summary, roughly one to three sentences.

## Fails

- The keyboard-accessibility comment was removed or no longer says why the element
  is a button.
- Any of the five slop items above survived.
- Classes that were not slop were reordered, or the `<button>` was changed to another
  element.
- `components/StatusBadge.vue` or `nuxt.config.ts` was modified.
- The response is a long report, a bulleted list of every edit, or a diff dump.
