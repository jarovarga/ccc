---
paths:
  - "**/*.{js,mjs}"
---

# JavaScript

These rules apply to JavaScript that runs in a browser. Target features that are Baseline Widely available unless the project declares other browser support; feature-detect newer APIs, never user agents, and keep a fallback.

## Modules and syntax

- Use modern vanilla JavaScript and ES modules unless the project uses CommonJS.
- Use `const` unless the value is reassigned, and never `var`.
- Compare with `===` and `!==` only.
- Use `Number.isFinite`, `Number.isNaN` and `Number.parseFloat`, and `Number.parseInt` with the radix `10`, instead of the global functions.
- Avoid circular imports.
- Lazy-load non-critical modules with dynamic `import()`.
- Use top-level `await` only in modules that nothing depends on.
- Name module-level constants in `UPPER_SNAKE_CASE`.
- Use optional chaining only for expected, handled absence.
- Use `??` when `0`, `false` or `""` must survive.
- Prefer non-mutating array methods such as `toSorted()`, `toReversed()` and `with()` when the original must stay unchanged.
- Use `structuredClone()` for deep copies.
- Never use `eval()`, `new Function()` or a string argument to a timer.

## Initialisation and DOM

- Enhance working HTML.
- Initialise explicitly from the entry point, not as an import side effect.
- Return safely when optional markup is missing.
- Add idempotency only when re-initialisation is realistic.
- Query from the narrowest useful scope.
- Guard every required query result, including each element when several are required.
- Cache stable DOM references at initialisation.
- Build DOM with `createElement`, `DocumentFragment`, `append`, `replaceChildren` and `remove`.
- Set dynamic text with `textContent`.
- Never pass input to `innerHTML`, `outerHTML`, `insertAdjacentHTML()` or `document.write()`.
- Use `dataset` for behaviour metadata, not state; keep state local to the module or closure.
- Use `classList.toggle()` with its boolean argument when the desired state is known.
- Use `FormData` instead of reading fields manually.
- Use the Constraint Validation API (`setCustomValidity()`, `reportValidity()`) instead of replacing native validation.

## Events

- Prefer one named handler to a new anonymous function per element.
- Use delegation only when it simplifies related descendants.
- Mark high-frequency listeners that never call `preventDefault()` as `{ passive: true }`.
- `touchstart`, `touchmove` and `wheel` listeners on `window`, `document`, `html` and `body` are passive by default, and `scroll` cannot be cancelled.
- Call `preventDefault()` only for intentional takeover, so that native browser behaviour is preserved.
- Keep non-left link clicks and those modified with Ctrl, Meta, Shift or Alt native.
- Read keys with `event.key`, never `keyCode`.

## Focus and accessibility

- Close custom popups with Escape.
- Move focus into opened custom UI and return it to the trigger on close.
- Keep `hidden` and `inert` in sync with state.
- Keep cloned or inactive content non-interactive.
- Announce status updates through a live region (`role="status"` or `aria-live`) that exists before the update.

## Motion

- Use CSS for presentational motion.
- Use the Web Animations API or `requestAnimationFrame` for runtime measurement, sequencing or control.
- Check `matchMedia("(prefers-reduced-motion: reduce)")` before non-essential motion and react to live preference changes.
- On resize, update existing keyframes or timing instead of recreating the animation.
- Read design values such as durations or easing from CSS custom properties with a fallback instead of duplicating them in JavaScript.

## Observers and lifecycle

- Prefer `IntersectionObserver` and `ResizeObserver` to continuous scroll or resize handling.
- Give optional functionality a simple native fallback when reasonable; never load polyfills automatically.
- Disconnect observers once they are no longer needed and `unobserve()` handled one-shot targets.
- Cancel unused animations or frames.
- Implement full teardown, such as removing listeners through an `AbortController` signal, only for components with a real lifecycle.

## Timing and performance

- Use timers only for real timing or as a yielding fallback, never to wait for layout, DOM readiness, animation or fonts.
- Use `document.fonts?.ready` for final font metrics.
- Batch visual work and deduplicate pending frames.
- Separate layout reads from writes.
- Yield in tasks longer than 50 ms with `scheduler.yield()` where available, falling back to `setTimeout`.

## Data and network

- Take multiple optional parameters as an options object with defaults.
- Validate values where invalid input would break behaviour.
- Build URLs with `URL` and `URLSearchParams`.
- Use `fetch`, never `XMLHttpRequest`.
- Wrap `localStorage` and `sessionStorage` access in `try/catch`.
- Never store secrets in `localStorage` or `sessionStorage`.
- Check `event.origin` in `message` handlers.
- Check `response.ok` after `fetch`.
- Limit the time of a `fetch` with `AbortSignal.timeout()` and cancel it with `AbortController`.
- Treat `AbortError` as expected cancellation and `TimeoutError` as a failure.
- Await or handle every promise.

## Docblocks

- Write the documentation of public APIs as JSDoc, including options and defaults.
