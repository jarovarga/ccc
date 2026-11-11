---
paths:
  - "**/*.php"
---

# PHP

The target PHP version is the one the project declares in `composer.json` (`require.php`). A rule marked with a minimum version, such as (8.4+), applies from that version.

## Files and types

- Start every PHP file with `declare(strict_types=1);`; templates are exempt.
- Import namespaced classes, interfaces, traits and enums with `use`.
- Refer to imported names by their short name in code and docblocks, never by a fully qualified name such as `App\Model\Entity\User`.
- Use typed properties, typed class constants (8.3+), enums, `readonly` and promoted constructor properties.
- Use asymmetric visibility (`public private(set)`) and property hooks (both 8.4+) instead of getters and setters that only guard access.

## Classes

- Mark classes `final` unless designed for extension.
- Mark stateless classes `final readonly` (8.2+).
- Build changed copies of `readonly` objects with `clone($this, ['property' => $value])` (8.5+).
- Mark functions whose result must be used `#[\NoDiscard]` (8.5+).
- Discard a `#[\NoDiscard]` result deliberately with `(void)`.
- Mark overriding methods (8.3+) and properties (8.5+) `#[\Override]`.
- Mark classes outside a library's public API `@internal`.

## Syntax and control flow

- Write `new X()->method()` (8.4+) without wrapping parentheses.
- Use `match` to map a value to a result.
- Keep `switch` for branches that run several statements or need fall-through.
- Use the pipe operator `|>` (8.5+) for linear transformations of one value, not for side effects.
- Compare with `===`; `strict_types` does not affect comparisons.
- Pass `true` as the strict argument of `in_array()` and `array_search()`.
- Never use the `@` operator; use `??` or an explicit check instead.
- Never use `extract()`, `eval()` or variable variables.

## Standard library

- Use `array_first()` and `array_last()` (8.5+) instead of manual indexing.
- Use `array_find()`, `array_find_key()`, `array_any()` and `array_all()` (8.4+) instead of loops.
- Use `Uri\Rfc3986\Uri` or `Uri\WhatWg\Url` (8.5+) instead of `parse_url()`.
- Use `Dom\HTMLDocument` (8.4+) to parse HTML.
- Use `DateTimeImmutable` with an explicit `DateTimeZone('UTC')` instead of `date()`, `strtotime()` or `DateTime`.
- Use `DateInterval` for calendar arithmetic.
- Inject a PSR-20 `ClockInterface` where behaviour depends on the current time.

## Strings and regular expressions

- Use `mb_trim()`, `mb_ucfirst()` and `mb_lcfirst()` (8.4+) for text that can contain non-ASCII characters.
- End anchored regexes with the `D` modifier so that `$` does not match before a trailing newline.

## Errors

- Compare the result of a function that signals failure with `false` or `null` exactly, such as `preg_match(...) === 1`, `filter_var(...) === false` or `preg_replace(...) === null`.
- Decode and encode JSON with `JSON_THROW_ON_ERROR`.
- Use multi-catch (`catch (A | B $e)`) for shared handling.
- Omit an unused exception variable (`catch (A)`).
- Release resources in `finally`.
- Extend an SPL exception (`RuntimeException` or `LogicException`) and keep concrete exceptions `final`.

## Deprecated forms

- Use canonical casts: `(int)`, `(bool)`, `(float)`, `(string)`.
- Never use backticks; run external commands as described under Security.
- Use `__serialize()` and `__unserialize()` instead of `__sleep()` and `__wakeup()`.
- Use `str_increment()` (8.3+) to increment strings.
- Use `http_get_last_response_headers()` (8.4+) instead of `$http_response_header`.
- Do not call `curl_close()`, `finfo_close()` or `imagedestroy()`.

## Security

- Hash passwords with `password_hash()` and `PASSWORD_DEFAULT`.
- Rehash on login when `password_needs_rehash()` returns true.
- Generate tokens and security-relevant random values with `random_bytes()`, `random_int()` or `Random\Randomizer` (8.2+), never `rand()`, `mt_rand()` or `uniqid()`.
- Compare secrets with `hash_equals()`.
- Escape HTML with `htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8')`.
- Run external commands with `proc_open()` and an array command, which bypasses the shell; otherwise escape every argument with `escapeshellarg()`.
- Normalise file paths with `realpath()`.

## Docblocks

- Specify generics and shapes: `list<string>`, `array<string, mixed>`, `array{start: int, size: int}`.
