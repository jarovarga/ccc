---
paths:
  - "**/*.css"
  - "**/*.webmanifest"
  - "**/*.{html,twig}"
  - "**/*.{js,mjs}"
  - "**/manifest.json"
---

# PWA

These rules apply to installable, offline-capable web apps.

Where the project uses a library such as Workbox, configure the behaviour below through it.

## Delivery

- Serve the app over HTTPS; `localhost` qualifies as a secure context, a plain `http://` address on the local network does not.
- Resolve manifest and worker URLs relative to the app's scope, so that the app also works from a subpath.
- Serve the manifest as `application/manifest+json`.
- Generate from the build output:
  - the cache version, a content hash of the built files;
  - the precache list.
- Keep files the app does not use out of the build output.
- Never maintain the cache version or the precache list by hand.
- Treat the built manifest and worker as generated output:
  - ignore them in Git;
  - lint the worker source with service-worker globals, such as `globals.serviceworker` in ESLint.

## Manifest

- Set `id`, `name`, `short_name`, `description`, `lang`, `dir`, `start_url`, `scope`, `display`, `theme_color` and `background_color`.
- Match `theme_color` to the `theme-color` meta tag and `background_color` to the first painted background.
- Never change `id` after release, because browsers then treat the app as a new one.
- Set `id` before changing `start_url`, because without an `id` the `start_url` identifies the app.
- Provide icons:
  - an SVG icon with `"purpose": "any"`;
  - PNG icons of 192 and 512 pixels;
  - a separate 512-pixel `maskable` PNG whose content stays inside the central safe zone.
- Never combine purposes as `"any maskable"`.
- Add `screenshots` only when the richer Chromium install dialogue is wanted.
- Keep the manifest reachable: when Chrome on Android cannot fetch it, it may wait up to 30 days before checking again.
- Expect no metadata updates on iOS, iPadOS and Android browsers other than Chrome: a new name or icon reaches users only after they reinstall.

## Service worker

- Serve the worker from the root of the path it controls.
- Register it with `updateViaCache: 'none'`.
- Serve it and its imported scripts with `Cache-Control: max-age=0`, because older browsers may otherwise reuse a cached copy for up to 24 hours.
- Never rename or move the worker URL after release, because the old registration keeps controlling its clients.
- To retire a worker, deploy one at the same URL that:
  - deletes its caches;
  - calls `self.registration.unregister()`.
- Name caches with an app prefix and the build hash:
  - precache the shell in `install` with `new Request(url, { cache: 'reload' })`, so that no stale HTTP-cached file enters the new cache;
  - delete in `activate` only the caches with the app's own prefix, so that old caches are cleaned up.
- Wrap all asynchronous work in `install` and `activate` in `event.waitUntil()`.
- Handle only same-origin `GET` requests; return without `respondWith()` for everything else.
- Choose the cache strategy by content type:
  - hashed or versioned assets: cache-first by their full URL;
  - navigations in a single-page app: from the cached shell;
  - navigations in a multipage site: network-first with a cached fallback;
  - a navigation that finds neither: a short `503` offline response instead of the browser's error page.
- Use `ignoreSearch: true` only when the cache holds a single build and the HTML that references the assets comes from the same cache.
- Cache only `ok` responses at runtime.
- Never cache personalised responses or responses that carry authentication.
- Keep the worker free of DOM and `localStorage`, which do not exist there; use the Cache API or IndexedDB.
- Choose the update strategy deliberately:
  - by default, let the new worker wait and call `skipWaiting()` only after the user accepts the update notice;
  - call `skipWaiting()` and `clients.claim()` immediately only when an old page can keep running against the new worker.

## Document head

- Link the manifest with `rel="manifest"`.
- Keep a 180-pixel PNG `apple-touch-icon` with an opaque background, because iOS fills transparent pixels with black.
- Keep `apple-mobile-web-app-title` for the Home Screen label.
- Omit `apple-mobile-web-app-capable` when the manifest sets `display`; where older iOS still needs it, add `mobile-web-app-capable` next to it.
- Set the viewport meta tag to `width=device-width, viewport-fit=cover` only under one condition:
  - content has padding from `env(safe-area-inset-*)` on every edge that it reaches.
- Set `apple-mobile-web-app-status-bar-style` to `black-translucent` only under the same condition.
- Do not ship `apple-touch-startup-image` sets:
  - they need an image for every device resolution and constant upkeep;
  - WebKit may still flash white with one (WebKit bug 215479).
- Document the white flash on iOS as a known limitation:
  - iOS ignores `background_color`;
  - it shows its own splash screen when the app opens from the Home Screen.

## Registration and updates

- Register the worker from the entry point after the page has loaded and after feature detection.
- Report a failed registration with `console.warn` or `console.error` instead of throwing.
- On development hosts, such as `localhost`, `127.0.0.1` and `[::1]`, skip registration and unregister earlier workers and delete their caches.
- Check for updates with `registration.update()` when `visibilitychange` reports the page as visible, throttled to a minimum interval.
- Show the update notice to match the update strategy:
  - with a waiting worker:
    - show it when `registration.waiting` is set or `updatefound` reaches `installed` while the page has a controller;
    - after the user accepts, post a message that makes the worker call `skipWaiting()`;
    - then reload on `controllerchange`;
  - with an immediate `skipWaiting()`, offer the reload on `controllerchange`, but only when the page already had a controller at load.
- Never reload the page without the user's consent.
- Never block content behind installation.

## App-like interface

- Make an installed web app feel like an app:
  - set `touch-action: manipulation` on `html` and on scroll containers to stop the double-tap zoom on iOS while keeping pinch zoom;
  - set `-webkit-tap-highlight-color: transparent` only when every control has its own visible `:active` and `:focus-visible` states;
  - hide the scrollbar and its gutter on touch screens with `scrollbar-width: none` and `scrollbar-gutter: auto` inside `@media (pointer: coarse)`.
- Keep content inside the safe areas of an installed web app:
  - pad the top of every screen by `env(safe-area-inset-top)` plus extra space, not only full-screen views;
  - this keeps content clear of the soft fade that iOS draws under a translucent status bar;
  - pin a full-screen view with `position: fixed` and `inset: 0`;
  - do not size it with viewport units, which fall short of the visible area in the installed app on iPhone;
  - pad each safe area only once;
  - give `body` the background of an open full-screen view, for example with `body:has()`, because the view can stop above the bottom safe area.
- Scope standalone-only styles with `@media (display-mode: standalone)`:
  - check full-height layouts on a device;
  - on iPhone the layout viewport and viewport units are shorter than the screen by the top safe area;
  - extend a fixed full-screen view there with `inset-block-end: calc(env(safe-area-inset-top) * -1)`.

## Standalone runtime

- Expect a Home Screen app to be resumed, not reloaded.
- On `visibilitychange`, restore what the system suspended:
  - the wake lock;
  - the `AudioContext`;
  - the update check.
- Derive elapsed time from `Date.now()` timestamps, not counted ticks, because timers are throttled or suspended in the background.
- Save the state of a running activity, such as a timer, because iOS can end a Home Screen app in the background and an accepted update reloads it:
  - store it with a timestamp when the page is hidden and on `pagehide`;
  - offer to resume it at the next start;
  - discard it after a maximum age.
- Create or resume audio from a user gesture, and on iOS also play a short silent buffer inside it; resume the context after an interruption.
- Schedule sound cues on the `AudioContext` clock:
  - a short lookahead in advance;
  - skipping cues that fell due too long ago;
  - cancelling and scheduling them again from the real elapsed time when the page returns.
- Use a screen wake lock:
  - request it only during the activity that needs it and release it afterwards;
  - request it again when the page becomes visible;
  - offer a setting to turn it off.
- Provide in-app navigation and a way to reload or update, because standalone mode has no browser controls.

## Storage

- Store data and exports with a schema version.
- When stored data has an unknown version or cannot be read:
  - keep a backup copy before starting afresh;
  - stop writing while no backup could be made.

## Verification

- Test the production build over HTTPS on a host where the worker registers, such as a staging site or a tunnel.
- Do not test it on a development host that skips registration.
- Check the manifest, the worker and the caches in the DevTools Application panel.
- Verify:
  - an offline start after the first load;
  - an update across two consecutive builds;
  - the first install, which must not show the update notice;
  - that a running activity survives the app being ended in the background and an accepted update.
- Test on a real iPhone, or in the iOS Simulator of Xcode, added to the Home Screen.
