---
paths:
  - "**/*.{js,mjs}"
---

# JavaScript

## Modules

- Name files in lowercase kebab-case.
- Keep one behaviour per module.
- Export each behaviour as a named arrow function and never as a default export.
- Expose the smallest useful public API:
  - one `init(selector, options)`;
  - or an object of related behaviour functions that take selectors and options.
- Name behaviour functions in `camelCase` with a natural word where one fits, such as `navigation.scrollSpy()` or `toggle()`.
- Put option defaults in the function signature.
- Take the selector of the markup as a parameter with the default hook, such as `selector = '[data-notice="update"]'`.
- Name hooks by role: `data-action`, `data-notice`, `data-section` and `data-status`.
- Use arrows for local helpers and closures, and method syntax for the methods of an object API.

## Entry point

- Wire all behaviour in one entry point.
- Import each module there as a `camelCase` namespace, such as `import * as navigation from './modules/navigation.js'`.
- Call the functions of each module with selectors and options.
- Do not attach APIs to `window`.
- Do not wait for `DOMContentLoaded` in a module script, because module scripts are already deferred.
- Wait for `load`, with `{ once: true }`, only for work that has to follow it, such as registering a service worker.

## Syntax

- Use arrow functions for callbacks.
- Return early instead of using `else` after a `return`.
- Omit the braces of a block only when its body fits on one line.
- Do not mark a function `async` unless it awaits.

## DOM

- Attach listeners with `addEventListener`, never through `on…` properties.
- Change classes with `classList`, never by assigning `className`.
- Build markup with native DOM methods, and never assign `innerHTML` or `outerHTML` or call `insertAdjacentHTML()`.

## Errors

- Report a handled failure with `console.warn` or `console.error`:
  - with a sentence that says what failed, such as `'The update check failed.'`;
  - with the error as the last argument.

## Service worker

- Name each event handler `handle<Event>`, such as `handleFetch`, and declare it as an arrow function.
- Register all handlers together at the end of the file.

## Tests

- Write a decision that depends on the browser as a pure function of an injected environment, so that tests run without a browser.
- Read the environment in one small function.
- Test with `node:test` and `node:assert/strict`.
- Keep the tests in `tests/`, in `<module>.test.js`, and import the module under test.
- Name each test with a sentence that states the behaviour.
- Build test inputs with a factory function that takes the changes to a default input.
- Keep helpers shared by several tests in `tests/helpers/`.
- Replace a global for the length of one test and put the original back afterwards.
- Collect what the code under test writes with `console.warn` instead of letting it clutter the output.

## Docblocks

- Keep each JSDoc tag with its type, name and description on one line, even beyond the usual line limit.
- Never hard-wrap a docblock.
- Document private helpers as well as exports:
  - with a summary sentence;
  - with a `@param` for each parameter, and optional ones in brackets;
  - with a `@returns`.
- Cast the result of a query with an inline `@type` comment, such as `/** @type {HTMLElement} */ (document.querySelector(selector))`.
