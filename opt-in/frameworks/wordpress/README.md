# WordPress

Settings and rules for themes for WordPress.

## Installation

Copy `rules/` into the project's `.claude/rules/`, and merge `settings.json` into the project's `.claude/settings.json`. If the project has no settings file yet, copy it.

Join the project's own `permissions.allow`, `ask` and `deny` lists with those of the framework instead of replacing them, and check every scalar value that both files set.

The project root is the root of the WordPress installation, which holds `wp-config.php` and `wp-content/`. Run Claude Code from it, because the paths in the files are relative to it and `wp` finds the installation there.

## Settings

| Setting | Reason |
| --- | --- |
| `claudeMdExcludes` | Keeps the `CLAUDE.md` files and rules of Composer and npm packages in `vendor/` and `node_modules/` from loading. |
| `worktree.symlinkDirectories` | Links `node_modules/` and `vendor/` into a worktree instead of copying them. |
| `allow` for `wp core version`, `wp option get`, `wp plugin list`, `wp theme list`, `wp cron event list` and `wp rewrite list` | These only read and report. |
| `allow` for `npm run build`, `format:check` and `lint` | They only build, read and report. The rules match these scripts exactly, so `lint:fix` still needs a decision. |
| `allow` for PHPCS and PHPStan | These only read code and report. |
| `allow` for `WebFetch` | The WordPress Developer Resources, the Make WordPress blogs, the MariaDB documentation and the PHP manual are official documentation. |
| `ask` for `wp eval`, `wp eval-file`, `wp shell` and `wp package install` | They run arbitrary PHP. |
| `ask` for `wp db`, `wp search-replace`, `wp site empty`, `wp post delete`, `wp user`, `wp option add`, `update`, `patch` and `delete`, `wp cache flush` and `wp transient delete` | They read or change the database. |
| `ask` for installing, updating, activating, deactivating and deleting plugins and themes, `wp core download`, `wp core update` and `wp scaffold` | They change code or the site. |
| `ask` for `composer install`, `require`, `update` and `remove`, and `npm install`, `uninstall` and `update` | Dependency changes need a decision. |
| `deny` for `wp config` | `wp config get` and `list` print the database password and the salts. A global parameter before the subcommand, such as `wp --path=. config get`, does not match the rule; `sandbox.credentials.files` is what keeps `wp-config.php` from being read. |
| `deny` for `Read` and `Edit` on `.npmrc` and `auth.json` | They hold the tokens of npm and Composer registries. The rules match at any depth in the project, not in the home directory. |
| `deny` for `Read` and `Edit` on `wp-config.php`, and `sandbox.credentials.files` for `./wp-config.php` | The file holds the database credentials and the salts. The `Read` and `Edit` rule matches at any depth; change the sandbox path when WordPress lives in a subdirectory, such as `./wordpress/wp-config.php`. |

The stack rule `html.md` loads only for `.html` and `.twig` files. To apply it to the templates, copy it into the project's `.claude/rules/` and set its `paths` to the template files of the theme, such as `wp-content/themes/*/*.php`, `wp-content/themes/*/template-parts/**/*.php` and `wp-content/themes/*/templates/**/*.php`.

Prefix the `wp`, PHPCS and PHPStan commands with the wrapper of the project when they run in a container, as described in the main README under Per-project settings.
