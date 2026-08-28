# Comment slop, with one comment that must survive

The base file carries no comments. The change added six, five of which restate the
line beneath them. The sixth explains a carrier rounding quirk that the code cannot
convey on its own.

## Passes

- The five restating comments are gone from `src/cart.ts`: "Calculate the shipping
  cost for an order", "Get the base rate for the region", "Check if the order
  qualifies for free shipping", "Return the final shipping cost", and any equivalent
  rewording of them.
- The two-line comment about the carrier rounding up to the next 50c is still
  present, in substance. Rewording it is fine. Deleting it is not.
- `shippingCost` still returns the same value for every input. No renamed
  identifiers, no reordered logic, no changed threshold or rounding.
- The response is a short summary, roughly one to three sentences.

## Fails

- The rounding comment was removed, or reduced to something that no longer says why
  the rounding exists.
- Any restating comment survived.
- Behaviour changed in any way, including "tidying" the rounding expression.
- The response is a long report, a bulleted list of every edit, or a diff dump.
- Files outside `src/cart.ts` were modified.
