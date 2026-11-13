---
paths:
  - "wp-content/themes/**/*.php"
---

# WordPress

These rules apply to themes for WordPress.

Target the WordPress version the project declares. A rule marked with a minimum version, such as (6.5+), applies from that version.

## Framework equivalents

- Use the WordPress API instead of the native one:
  - `$wpdb->prepare()` or `WP_Query` instead of raw SQL;
  - `wp_remote_get()` and `wp_remote_post()` instead of cURL;
  - `wp_safe_redirect()` followed by `exit` instead of `header( 'Location: …' )`;
  - `wp_json_encode()` with `JSON_THROW_ON_ERROR` instead of `json_encode()`;
  - `wp_parse_url()` instead of `parse_url()`, `Uri\Rfc3986\Uri` and `Uri\WhatWg\Url`;
  - `wp_delete_file()` instead of `unlink()`;
  - `wp_strip_all_tags()` instead of `strip_tags()`;
  - the Transients or Object Cache API instead of direct cache clients;
  - `wp_handle_upload()` with `wp_check_filetype_and_ext()` instead of `move_uploaded_file()`;
  - `wp search-replace` instead of SQL `REPLACE()` for URL or domain changes, because options and meta hold serialised data;
  - `wp_generate_password()` or `wp_rand()` instead of custom random generators;
  - `esc_html()`, `esc_attr()` and related functions instead of `htmlspecialchars()`;
  - `wp_hash_password()` and `wp_check_password()` instead of `password_hash()` and `password_verify()`;
  - `time()` or `current_time( 'mysql', true )` for stored UTC times;
  - `wp_date()`, `current_datetime()` and `wp_timezone()` instead of `date()`, only for display in the site timezone;
  - `wp_mail()` instead of `mail()`;
  - `wp_get_attachment_image()` instead of a handwritten `img` for attachments, because it adds `srcset`, `sizes`, dimensions and lazy loading.

## Architecture

- Guard plugin integrations with a `class_exists()` or `function_exists()` check so the theme works without the plugin.
- Keep child-theme template parts in `template-parts/`.
- Name files by WordPress convention (`class-*.php`, `interface-*.php`).
- Start every PHP file of the theme, templates included, with `defined( 'ABSPATH' ) || exit;`; in a file with `declare(strict_types=1);`, put the guard directly after it, because `declare` must be the first statement.
- Hook into the narrowest action or filter and register callbacks as methods or static closures; never execute logic on file load.
- Return a value from every filter callback and keep filters free of side effects; use actions for side effects.
- Change the main query in `pre_get_posts` guarded by `is_main_query()` and `! is_admin()`; never use `query_posts()`.
- Call `wp_reset_postdata()` after every custom `WP_Query` loop.
- Prefer the REST API to `admin-ajax.php` for new endpoints.
- Pass server data to script modules through the `script_module_data_{$module_id}` filter (6.7+) instead of inline globals.
- Use `get_template_directory*()` for parent-theme files and `get_stylesheet_directory*()` for child-theme files.
- Prefix custom hooks, options, transients and meta keys with the theme slug.
- Load templates through the template hierarchy and `get_template_part()` with `$args` instead of `include`.
- Schedule recurring work with `wp_schedule_event()` guarded by `wp_next_scheduled()`, and unschedule it when the feature is removed.
- Store only disposable data in transients; a transient can disappear before its expiry.

## Code standards

- Follow the WordPress Coding Standards, checked with PHP_CodeSniffer.
- Indent PHP, including templates, with tabs.
- Align the `=` of consecutive assignments and the `=>` of key-value pairs.
- Run PHPStan at level `max`, so that new code is fully typed.
- Declare new global constants in `phpstan-bootstrap.php` and list them under `dynamicConstantNames` in `phpstan.neon`.
- Keep PHP lines in the `src/` directory of a theme at 120 characters or fewer.
- Never wrap comments; they are exempt from the line limit.
- Keep every HTML tag in a template on one line, however long it is; templates are exempt from the line limit.

## PHP

- Name classes `Upper_Snake_Case`.
- Give every function and method a one-line summary plus `@param`, `@return` and `@throws` as WordPress Coding Standards require.
- Explain the reason in a docblock rather than restate the signature.
- Check `is_wp_error()` on every WordPress function that can return `WP_Error`.

## Translations

- Write user-facing strings with `__()`, `esc_html__()`, `esc_attr__()` and related functions.
- Pass the theme's text domain.
- Use `_n()` for plurals and `sprintf()` placeholders instead of concatenating translated fragments.

## Email

- Send form emails with `wp_mail()` from an address on the site's domain.
- Put the visitor's address in `Reply-To` and start the subject with the form's unique name.

## Security

- Unslash input with `wp_unslash()`, then sanitise it with `sanitize_*()` or `absint()` at the boundary.
- Escape late in templates with `esc_html()`, `esc_attr()`, `esc_url()` or `wp_kses_post()`.
- Use `%i` placeholders for identifiers in `$wpdb->prepare()` (6.2+).
- Protect every state-changing request with a nonce (`wp_nonce_field()`, `check_admin_referer()`, `check_ajax_referer()`, `wp_verify_nonce()`).
- Protect every state-changing request of a logged-in user with a `current_user_can()` capability check.
- Verify the nonce of a visitor form with `wp_verify_nonce()` and keep the page out of the page cache; visitor forms have no capability to check, and a cached nonce expires.
- Give every `register_rest_route()` a `permission_callback` that checks capabilities.
- Never return `true` from the `permission_callback` of a route that changes data.
- Pass a `timeout` to every `wp_remote_*()` call and handle `WP_Error` explicitly.
- Use `wp_safe_remote_get()` and `wp_safe_remote_post()` for URLs that users can influence.

## Performance

- In `WP_Query`, set `no_found_rows` when not paginating and `fields => 'ids'` when only IDs are needed.
- Never use `posts_per_page => -1` on unbounded data.
- Disable autoload for large or rarely read options.
- Send `nocache_headers()` for personalised responses.

## Assets

- Enqueue assets with `wp_enqueue_style()` and `wp_enqueue_script_module()` (6.5+) using the theme version for cache busting.
- Enqueue classic scripts that depend on jQuery or the global `wp` object with `wp_enqueue_script()`.
- Declare the dependencies of assets and enqueue them only on pages that need them.
- Never print `<link>` or `<script>` tags directly.

## Documentation

- The WordPress Developer Resources (https://developer.wordpress.org/reference/) are authoritative.
- The WordPress Coding Standards handbook (https://developer.wordpress.org/coding-standards/) is authoritative.
- Consult them before relying on memory.
