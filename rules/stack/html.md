---
paths:
  - "**/*.{html,twig}"
---

# HTML

Target features that are Baseline Widely available unless the project declares other browser support; use a newer feature only where the page stays functional without it.

## Structure and semantics

- Set `lang` on `html` and on passages in another language.
- Choose elements by meaning, not appearance.
- Use `div` or `span` only when no semantic element fits; avoid wrappers that exist only as styling hooks.
- Keep only the primary page content in `main`, not repeated navigation or footer content.
- Use `section` for a thematic section that normally has a heading and `article` for self-contained content, never because a component looks like a section or card.
- Make the `h1` describe the primary content.
- Never pick a heading level for its visual size.
- Treat logos as identity, not headings.
- Do not give a logo link the same accessible name in both image `alt` and `aria-label`.
- Mark up page regions with landmarks, including `search`.
- Consider a skip link to `main` when long repeated navigation precedes it; landmarks may suffice for short navigation.
- Use `ul`, `ol` or `dl` for lists, including navigation menus.
- Use tables only for tabular data, except for layout in HTML email.
- Give data tables a `caption` where needed.
- Never use `br` or empty elements for spacing.
- Use `time` with a machine-readable `datetime` for dates and times.

## Attributes

- Add classes only where styling or scripting needs them.
- Add IDs only for fragments or form or ARIA relationships, never for styling.
- Hook scripts to `data-*` attributes or classes rather than IDs.
- Keep field names that a server-side framework or CMS dictates.
- Avoid positive `tabindex`.

## Links and buttons

- Use `button` for actions and `a` for navigation, never `href="#"` as a button.
- Write descriptive link text.
- Do not rely on `<base>`.
- Do not open external links in new tabs automatically.
- Give `target="_blank"` links `rel="noopener"` for older browsers; add `noreferrer` only when the referrer must be hidden.
- Give icon-only controls an `aria-label`.
- Give an icon-only control that controls other content or toggles `aria-controls`, `aria-expanded` or `aria-pressed`.

## Forms

- Keep labels visible; a `placeholder` is not a label.
- Link hints and errors with `aria-describedby` and mark invalid fields with `aria-invalid`.
- Prefer specific input types, native constraints and `inputmode` to JavaScript validation.
- Use `type="text"` with `inputmode="numeric"` for numeric identifiers such as card numbers, postcodes or codes.
- Set `autocomplete` on personal-data and credential fields, such as `given-name`, `email`, `current-password`, `new-password` or `one-time-code`.
- Use `autocomplete="off"` only when necessary.
- Group related controls with `fieldset` and `legend`.

## Native widgets

- Prefer native `details` and `summary`, `dialog` and native form controls to custom widgets.
- Use the `popover` attribute for non-modal overlays where the target supports it.
- Give each `dialog` an accessible name and an explicit close button.
- Open a modal `dialog` with `showModal()`.
- Set `autofocus` on the primary control of a `dialog` and never put `tabindex` on the `dialog` itself.
- Handle closing and focus of a `dialog`.

## Accessibility

- Use ARIA only where native semantics cannot express the role, state or relationship; never use it to patch an inappropriate native element.
- Give every control an accessible name.
- Keep ARIA states in sync with the interface and remove stale ones.
- Hide decorative content with `aria-hidden="true"`.
- Use `inert` or `hidden` for inactive content; `aria-hidden` alone does not prevent focus or interaction.
- Where animated text stands in for a real value, also give the value in a visually hidden element.

## Images and media

- Give informative images meaningful `alt` text and decorative ones `alt=""`.
- In `alt`, avoid filenames, phrases such as 'image of' and duplicated nearby text; do not repeat `alt` in `title`.
- Supply known intrinsic `width` and `height`.
- Use `srcset`, `sizes` or `picture` for responsive images.
- Serve AVIF or WebP through `picture` with a fallback `img`.
- Give informative inline SVG `role="img"` and an accessible name; hide decorative SVG with `aria-hidden="true"`.
- Lazy-load below-the-fold images and iframes with `loading="lazy"`, never images critical to the initial viewport.
- Give the key above-the-fold image `fetchpriority="high"` and non-critical images `decoding="async"`.
- Use `figure` with `figcaption` for captioned self-contained content, not as a generic image wrapper.
- Autoplay video only when it is `muted` and `playsinline`.
- Provide captions and transcripts for audio and video content.
- Give content that moves, blinks, scrolls or plays automatically for more than five seconds a way to pause, stop or hide it.

## Resources and metadata

- Use external scripts.
- Load ES modules with `type="module"`, which defers them.
- Use `defer` for classic scripts that need the DOM and `async` only for independent ones.
- Without a bundler, declare an inline import map, which cannot be external, before any module that uses bare specifiers.
- Never add inline event handlers.
- Add `crossorigin` to cross-origin resources that use Subresource Integrity.
- Sandbox third-party iframes with the fewest permissions they need.
- Keep `<meta charset="utf-8">` within the first 1024 bytes of the document.
- Add canonical URLs, robots directives, social metadata or structured data only when required.
- Add `preload`, `preconnect` and `dns-prefetch` only for demonstrated needs.
- Never `preconnect` same-origin resources or preload resources not needed early.
- Provide a `<noscript>` fallback where content or function depends on JavaScript.
