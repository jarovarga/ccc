---
paths:
  - "**/*.css"
---

# CSS

Target features that are Baseline Widely available unless the project declares other browser support; use newer features with an `@supports` fallback.

## Cascade

- Resolve cascade conflicts with layers and source order instead of raising specificity.
- Declare the layer order once, in a single `@layer` statement at the start of the entry stylesheet.
- Import files with `layer()`.
- Never use `!important` or ID selectors.
- Do not qualify a class with a tag name, such as `div.card`.
- Nest rules at most two levels deep, not counting media, supports and container queries or pseudo-classes, and start every nested selector with `&`.
- Write the reset with zero specificity through `:where()` and without component styling.

## Tokens

- Write colours through tokens.
- Name custom properties and keyframes in lowercase words joined by single hyphens, and classes likewise except for the separators of a naming methodology such as BEM.
- Keep global design values in tokens: colours, fonts, text sizes, font weights, line heights, letter spacing, radii, blur, transition durations and easing.
- Do not duplicate a token's meaning.
- Keep component-specific custom properties on the component, not in `:root`.
- Reference only custom properties, animations and custom media that exist.
- Give every custom property a meaningful role; never wrap an arbitrary literal.
- Name colour tokens by purpose, such as `--color-surface`, not appearance.
- Add a variant token only when several components share it; derive one-off state shades, such as hover, in the component.
- Derive a variant token from its base with relative colour syntax, such as `--color-surface-raised: oklch(from var(--color-surface) calc(l + 0.1) c h)`.
- Declare a literal value first and the derived one inside `@supports (color: oklch(from red l c h))`, because a custom property accepts an unsupported value and then fails where it is used.
- Check the contrast of derived variants too.

## Layout and selectors

- Write the smallest layout as the base and try intrinsic layout before breakpoints.
- Add layout-driven, not device-specific, breakpoints.
- Nest each media query in the selector it changes, such as `@media (width >= 64rem)`, `@media (forced-colors: active)` or `@media (prefers-reduced-motion: reduce)`.
- Use media queries for page-level responsiveness and container queries when a component responds to its container.
- Set `container-type: inline-size` on a named container and use `cqi` units inside the query.
- Prefer logical properties such as `margin-block`, `padding-inline`, `inline-size` and logical insets and borders.
- Use `rem` for dimensions and insets, `em` for local font-relative values, `%` for relative sizes and `fr` for Grid, and never `px` for `font-size`.
- Use `svh` or `dvh` instead of `vh`.
- Use `:has()` only for a genuine relational requirement, not instead of a simple modifier.

## States and accessibility

- Style native states with pseudo-classes.
- Prefer a native or ARIA attribute, such as `hidden` or `aria-expanded`, to a state class, and add a state class only for a state that no attribute expresses.
- Treat hover as an enhancement that core functionality never depends on; gate it with pointer and hover queries where useful.
- Show focus with `:focus-visible` at an indicator contrast of at least 3:1.
- Keep focused elements clear of sticky headers and footers with `scroll-padding` or `scroll-margin`.
- Keep visual order consistent with DOM and keyboard order.
- Give pointer targets at least 24 × 24 CSS pixels or equivalent spacing (WCAG 2.5.8).
- Never convey information, such as state, by colour alone.
- Keep text contrast at least 4.5:1, or 3:1 for large text (WCAG 1.4.3).
- Implement dark mode, where the project offers it, through `color-scheme` and semantic tokens rather than per-component overrides.

## Hidden content

- Use `[hidden]` for visually and semantically hidden content.
- Keep `[hidden]:not([hidden="until-found"]) { display: none; }` in the final layer, because an authored `display` overrides the browser's `display: none`.
- Do not hide with `opacity: 0` alone; it does not remove interactivity.
- Hide screen-reader-only text with the project's visually-hidden class, not `[hidden]`.

## Forced colours

- Keep focus indicators and borders visible in forced-colours mode: use `outline` or `border`, not `box-shadow` or background alone.
- Give the outline a `transparent` colour where none should normally show.

## Motion

- Under reduced motion, remove scaling, panning and parallax, and keep essential interactions.
- Replace removed motion with an opacity change where feedback is needed.

## Quality

- Set `text-wrap: balance` on headings and `text-wrap: pretty` on paragraphs.
- Prefer local `woff2` fonts and set `font-display` to `swap`.
- Name the transitioned properties instead of `all`.
- Do not use `float` for layout.
- Use no scheme-relative URLs, such as `url(//example.com/a.png)`.
- Never duplicate `@font-face` per component or reference unloaded font weights.
- Diagnose stacking contexts instead of escalating `z-index`.
- Diagnose the cause of overflow instead of hiding it; use `overflow: clip` only for intentional clipping.
- Add vendor prefixes only when needed and keep intentional existing ones.
- After changing styles, check responsive layout, keyboard access, accessible states and reduced motion where relevant.
