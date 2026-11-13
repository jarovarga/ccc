# CakePHP

Settings and rules for projects built on CakePHP 5.x.

## Installation

Copy `rules/` into the project's `.claude/rules/`, and merge `settings.json` into the project's `.claude/settings.json`. If the project has no settings file yet, copy it.

Join the project's own `permissions.allow`, `ask` and `deny` lists with those of the framework instead of replacing them, and check every scalar value that both files set.

Run Claude Code from the project root, because the paths in the file are relative to it.

## Settings

| Setting | Reason |
| --- | --- |
| `claudeMdExcludes` | Keeps the `CLAUDE.md` files and rules of Composer and npm packages in `vendor/` and `node_modules/` from loading. |
| `worktree.symlinkDirectories` | Links `node_modules/` and `vendor/` into a worktree instead of copying them. |
| `allow` for `npm run build`, `format:check` and `lint` | They only build, read and report. |
| `allow` for PHP-CS-Fixer (`check`) and PHPStan | These only read code and report. |
| `allow` for PHPUnit | It runs the project's own tests, which execute the code and write to the test database, not to the working database. |
| `allow` for `WebFetch` | The CakePHP Cookbook and API reference, the PHP manual and the PostgreSQL documentation are official documentation. |
| `ask` for `bin/cake bake`, `bin/cake console`, `bin/cake migrations`, `bin/cake cache` and `bin/cake schema_cache` | Bake writes files, the console runs arbitrary PHP, migrations change the database and cache commands remove data. The project's own commands are not covered; add those that change data to `ask` in the project settings. |
| `ask` for `composer install`, `require`, `update` and `remove`, and `npm install`, `uninstall` and `update` | Dependency changes need a decision. |
| `deny` for `Read` and `Edit` on `.npmrc` and `auth.json` | They hold the tokens of npm and Composer registries. The rules match at any depth in the project, not in the home directory. |
| `deny` and `sandbox.credentials.files` for `config/app_local.php` | The file holds the database credentials and the `Security.salt`. The baseline covers `.env` files but not this file. |

The stack rule `html.md` loads only for `.html` and `.twig` files. To apply it to the templates, copy it into the project's `.claude/rules/` and set its `paths` to `templates/**/*.php`.

The stack rule `postgresql.md` loads only for `.sql` files. To apply it to the migrations, copy it into the project's `.claude/rules/` and set its `paths` to `config/Migrations/**/*.php`.

The commands assume that the tools run on the host. When they run in a container, replace the prefix with the wrapper script of the project, as described in the main README under Per-project settings.
