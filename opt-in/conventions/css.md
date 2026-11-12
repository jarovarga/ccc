---
paths:
  - "**/*.css"
  - "**/*.{js,mjs}"
---

# CSS

## BEM

- Name classes:
  - as `block__element--modifier`, in lowercase words joined by single hyphens, with `__` before an element and `--` before a modifier;
  - with a modifier that carries a value as `--name_value`, such as `button--size_large`;
  - by meaning and responsibility, not appearance.
- Organise the cascade:
  - style one block, with its elements and modifiers, per file or layer and name the file after the block;
  - resolve cascade conflicts with layers, BEM, source order and modifiers instead of raising specificity;
  - let a layer adapt only earlier layers, through a BEM mix on the same element.
- Use modifiers and states:
  - apply a modifier together with the base class, such as `class="button button--accent"`, never alone;
  - style a modifier with a selector on the modifier class, such as `.button--accent`, and not through the base class with a second condition;
  - style native states with pseudo-classes and variants with BEM modifiers.
- Keep blocks independent:
  - never nest selectors to follow the structure of the DOM: write `.card__title`, not `.card .card__body .card__title`;
  - never nest elements in a name: write `card__title`, not `card__body__title`;
  - never style an element outside its own block through a selector such as `.card .button`;
  - change a child block from a parent block through a modifier on the child or through a custom property;
  - adapt a block in another context with a mix: put a class of the context on the same element, such as `class="button intro__action"`.
- Keep selectors simple:
  - use at most two combinators and four compound selectors per selector;
  - keep the specificity at or below `0,3,1`, that is at most three classes, attributes or pseudo-classes and one type selector.
- Hook scripts to the markup through the base selector of the block:
  - build selectors for BEM elements and modifiers from it, such as `${selector}__viewport`;
  - never build them from DOM depth, such as `.menu > ul > li`.

## Layers

- Order the layers in ascending priority as `reset`, `base`, `helper`, `block`, `module`, `segment`, `util`.
- Import each file from `app.css` into its layer, then add the global `@font-face` rules.
- Keep the start of the cascade in root files:
  - `reset.css`: browser normalisation (layer `reset`);
  - `base.css`: global document styles, including `.container` and the keyframes shared by several files (layer `base`);
  - `tokens.css`: global design values (unlayered).
- Keep everything else in folders named after their layer in the plural:
  - `blocks/<block>.css`: reusable BEM blocks, with their elements and modifiers in the same file (layer `block`);
  - `helpers/<helper>.css`: reusable attribute helpers that blocks may adapt, such as `[data-icon]` icons (layer `helper`);
  - `modules/<module>.css`: standalone functional modules, such as a slider, counter or scroll effect, not meant for reuse (layer `module`);
  - `segments/<segment>.css`: styles for individual page parts (layer `segment`):
    - such as the header, each section in `main` and the footer;
    - import a frame shared by the sections first;
  - `utils/a11y.css`: focus styles, the `.visually-hidden` class and the global reduced-motion rule (layer `util`, which wins over all others);
  - `utils/states.css`: global states, including the `[hidden]` rule, imported last (layer `util`).
- Place new styles in the first matching location:
  - rules that must win over every other layer in `utils/`;
  - global rules in a root file;
  - adaptable helpers in `helpers/`;
  - page parts in `segments/`;
  - standalone features and effects in `modules/`;
  - other reusable blocks in `blocks/`.
- Create a file only when it has content to hold and import only existing files.

## Tokens

- Start the name of every token with the prefix of its group, and write the scale step last:
  - `--color-<role>` for colours;
  - `--font-sans`, `--font-display` and `--font-mono` for font families;
  - `--spacing` for the spacing unit;
  - `--text-<step>` for text sizes;
  - `--font-weight-<name>` for font weights;
  - `--tracking-<name>` for letter spacing;
  - `--leading-<name>` for line heights;
  - `--radius-<step>` for radii;
  - `--blur-<step>` for blur;
  - `--duration-<name>` for transition durations;
  - `--ease-<name>` for easing.
- Name the steps of each scale:
  - text sizes and radii from `xs` upwards, such as `--text-xs`, `--text-2xl` and `--radius-4xl`;
  - blur from `xs` to `3xl`;
  - font weights by their usual names, from `thin` to `black`;
  - letter spacing as `tighter`, `tight`, `normal`, `wide`, `wider` and `widest`;
  - line heights as `none`, `tight`, `snug`, `normal`, `relaxed` and `loose`;
  - durations as `fast` and `base`;
  - easing as `in`, `out` and `in-out`.
- Name colour variants with a suffix:
  - `-dim` and `-muted` for weaker shades;
  - `-overlay` for a translucent shade;
  - `-raised`, `-deep`, `-tint` and `-variant` for surfaces;
  - `--color-on-<role>` for content on a coloured surface, such as `--color-on-accent`.
- Write the values in fixed units:
  - `--spacing`, text sizes and radii in `rem`;
  - blur in `px`;
  - letter spacing in `em`;
  - line heights without a unit.
- Derive a translucent shade of a token with `color-mix`, such as `color-mix(in oklch, var(--phase) 25%, transparent)`.

## Values

- Write colours:
  - use no hex colours and no named colours;
  - use no `rgb()`, `rgba()`, `hsl()`, `hsla()`, `hwb()`, `lab()` or `lch()`;
  - write colours in OKLCH, such as `oklch(1 0 0)` for white;
  - write alpha, hue and lightness as plain numbers, such as `oklch(1 0 0 / 0.5)` for white at 50 % opacity.
- Write custom property names in lowercase kebab-case, with an optional `--modifier` suffix.
- Take typography and shape from tokens:
  - `font-size` and `line-height` from a token, `clamp()` with a token or `inherit`;
  - `font-weight` from a token, as a number or, for a variable font, as a range of two numbers;
  - `letter-spacing` from a token or `inherit`;
  - `border-radius` from a token, `0`, `50%` or `inherit`;
  - `transition-timing-function` and `animation-timing-function` from a token.
- Write no `em` in `block-size`, `inline-size` and `inset`, and no `px` there except `1px`.
- Take transition durations from tokens, not literals.
- Write one-off animation durations and delays as literals; use a token only when several animations share the value.
- Write keywords in lowercase and `@import` with a string.

## Spacing

- Use `--spacing` for authored `padding`, `margin` and `gap` lengths:
  - write fixed lengths as multiples, such as `calc(var(--spacing) * 4)`;
  - write fluid lengths with `clamp()`, `min()` or `max()` bounded by such multiples, such as `clamp(var(--spacing) * 4, 4vw, var(--spacing) * 8)`;
  - write no `px` or `em` literals there, and no `rem` literals outside `clamp()`, `min()` and `max()`;
  - do not use `--spacing` for dimensions or offsets.

## Icons

- Use Lucide icons and draw them as CSS masks, so that they need no extra requests and work offline.
- Draw every icon on `[data-icon]::after`:
  - with `aspect-ratio: 1`, `content: ""`, `display: inline-block` and `flex-shrink: 0`;
  - with the mask `var(--icon-source, none) center / contain no-repeat`, written as `-webkit-mask` and `mask`;
  - coloured through `background-color` from `--icon-color` and sized through `block-size` from `--icon-size`, both with a fallback.
- Set the source of each icon in its own rule, such as `[data-icon="menu"]`, as `--icon-source` with an inline SVG data URL:
  - with `viewBox='0 0 24 24'`, `fill='none'` and `stroke='black'`;
  - with `stroke-width='2'`, `stroke-linecap='round'` and `stroke-linejoin='round'`.
- Keep the licence notice of every icon source, such as the ISC notice of Lucide, in a preserved `/*! */` comment in the helper.
- Fall back to `currentColor` with `forced-color-adjust: none` in forced-colours mode, because masks paint with `background-color`.

## Keyframes

- Place keyframes by their use:
  - keep keyframes shared by several files with the base styles;
  - keep keyframes used by one file at the end of that file, prefixed with its name.

## Properties order

- Put `font-smoothing` first.
- Sort all other declarations alphabetically by property name, with an empty line before the first of them.
