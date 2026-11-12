---
paths:
  - "**/*.{html,twig}"
---

# HTML

## Markup

- Structure the page as:
  - a `header` with the navigation;
  - a `main` with one `section` per page part;
  - a `footer`.
- Give each section a kebab-case `id`, link to it from the navigation with a fragment and use an `id` on `body` as the top target.
- Set in `head`:
  - `description`, `viewport` and `color-scheme`;
  - the canonical link;
  - the icons: SVG and 96-pixel PNG.
- Put `<title>` first in `head`, directly followed by the `charset` declaration.
- Preload the logo and the fonts that the page uses early, and load the stylesheet in `head`.
- Place the entry script at the end of `body`.
- Keep every opening and closing tag with all its attributes on one line, even beyond the usual line limit.
- Do not rely on a formatter for HTML; keep indentation and layout correct by hand.
- Render icons with a `data-icon` attribute.

## Validation

- Write the doctype in lowercase.
- Write attribute names, `id` values, `name` values and class names in kebab-case, and class names in BEM notation:
  - keep the field names that a server-side framework or CMS dictates.
- Give every resource loaded from another origin a subresource integrity hash.
- Write internal links as relative links starting with `./`, or `mailto:` and `tel:`, and never as absolute paths.

## Attribute order

- Order attributes on handwritten elements in `body` by these groups, in the listed order, and keep the attribute order of framework helper output:
  - Group 1 (resource): `href`, `src`, `srcset`, `sizes`, `data`, `srcdoc`;
  - Group 2 (kind): `type`, `name`, `method`, `action`, `target`, `rel`, `datetime`;
  - Group 3 (description and dimensions): `label`, `kind`, `srclang`, `shape`, `coords`, `span`, `colspan`, `rowspan`, `scope`, `headers`, `abbr`, `start`, `cols`, `rows`, `size`, `wrap`, `width`, `height`, `poster`, `preload`;
  - Group 4 (constraints): `min`, `max`, `low`, `high`, `optimum`, `step`, `minlength`, `maxlength`, `pattern`, `accept`;
  - Group 5 (hints and loading): `placeholder`, `autocomplete`, `inputmode`, `enterkeyhint`, `list`, `dirname`, `hreflang`, `cite`, `download`, `ping`, `enctype`, `accept-charset`, `loading`, `fetchpriority`, `decoding`, `crossorigin`, `integrity`, `referrerpolicy`, `nonce`, `blocking`, `allow`, `sandbox`, `usemap`;
  - Group 6 (references to other elements): `for`, `form`, `formaction`, `formenctype`, `formmethod`, `formtarget`, `popovertarget`, `popovertargetaction`, `commandfor`, `command`;
  - Group 7 (other global attributes): `lang`, `dir`, `title`, `tabindex`, `accesskey`, `popover`, `translate`, `spellcheck`, `autocapitalize`, `contenteditable`, `draggable`, `slot`, `itemprop`, `itemid`, `itemref`, `itemtype`;
  - Group 8: `data-*`, then `alt`;
  - Group 9: `value`;
  - Group 10 (identity): `id`, `class`;
  - Group 11: `role`, then `aria-*`, with `aria-label` last;
  - Group 12 (valueless boolean attributes): alphabetically, such as `async`, `checked`, `defer`, `disabled`, `hidden`, `inert`, `multiple`, `novalidate`, `open`, `readonly`, `required` or `selected`.
- Place an attribute missing from the list with the closest group.
- Write `popover` with a value, `auto` or `manual`.
- Order attributes on `head` elements by identity first:
  - `meta` as `charset` or `name`, then `content`;
  - `link` as `href`, `rel`, `as`, `type`, `sizes`, `fetchpriority`, `crossorigin`.
