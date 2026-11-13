---
paths:
  - "config/**/*.php"
  - "plugins/**/*.php"
  - "src/**/*.php"
  - "templates/**/*.php"
  - "tests/**/*.php"
---

# CakePHP

These rules apply to projects built on CakePHP 5.x. A rule marked (PostgreSQL) applies where the project's database is PostgreSQL; a minimum version, such as (PostgreSQL 18+), applies from that version.

## Framework equivalents

- Use the CakePHP tool instead of the native one:
  - the ORM query builder instead of raw PDO;
  - `Security::randomString()` instead of `random_bytes()`;
  - `h()` instead of `htmlspecialchars()`;
  - `$request->getData()` with validators instead of `filter_input()`;
  - the `Cache` class instead of a direct Redis or Memcached client;
  - `Cake\I18n\DateTime` and `Date` instead of `DateTimeImmutable`;
  - `DateTime::now()` instead of an injected PSR-20 `ClockInterface`;
  - entity accessors and mutators (`_getX()`, `_setX()`) instead of property hooks on entity fields;
  - `Cake\Http\Client` with a timeout instead of cURL;
  - `Log` instead of `error_log()`.
- Hash passwords with the Authentication plugin's `DefaultPasswordHasher` when the plugin is installed.
- Use CakePHP 5.x APIs, not older forms:
  - `orderBy()` and `groupBy()` instead of `order()` and `group()`;
  - `expr()` instead of `newExpr()`;
  - `DateTime` and `Date` instead of the `FrozenTime` and `FrozenDate` aliases;
  - `fetchTable()` instead of `TableRegistry`;
  - named arguments for `find()` options.

## Code standards

- Follow PER-CS 3.0, checked with PHP-CS-Fixer on `src/` and `tests/`.
- Apply the PHP 8.5 and PHPUnit migration sets of PHP-CS-Fixer, with its strict comparison, strict types and import rules.
- Exclude `config/`, including migrations and seeds, from PHP-CS-Fixer.
- Run PHPStan at level `max` for `src/`, `templates/` and `tests/`, so that new code is fully typed.
- Declare template variables with `@var`.
- Narrow the return type of `h()` to a string for strings and objects with a PHPStan stub.
- Indent PHP, including the templates in `templates/`, with four spaces.
- Keep lines at 120 characters or fewer.

## Architecture

- Layer the code as controller → service → table.
- Return `void` from an action, or `?Response` when it redirects.
- Keep controllers thin: handle the request, authorisation and response only, and delegate business logic to services, tables and entities.
- In controller actions, catch only the specific exceptions that the action can handle, to log them and flash a generic message.
- Leave all other exceptions, including `RecordNotFoundException` and HTTP exceptions, to CakePHP's error handler at the entry point, so that they keep their status codes.
- Place services in `App\Service`:
  - in `Domain` one per table for the services that wrap one data source;
  - in `Feature` the services that coordinate several of those;
  - name them for the feature and group them by whom they serve, such as `Feature\User`;
  - split the services over one table by audience or concern:
    - `UsersService` for managing users as an admin;
    - `ProfileService` for the signed-in user editing their own profile.
- Make calculators stateless and have them implement an interface.
- Put each service interface in a `Contract/` directory beside the implementation and type against it.
- Keep services stateless: never store per-call state on a shared instance.
- Do not mark a class that extends a CakePHP class `readonly`, because a readonly class cannot extend a non-readonly parent.
- Pass associations as arguments, such as `get($id, contain: [...])`.
- Never keep a fluent `contain()` list on a shared service.
- Register event listeners in `Application::events()`, not in `bootstrap()`.
- Dispatch events named `Domain.action` for side effects such as cache invalidation.
- Use the suffixes `XService`, `XServiceInterface`, `XMiddleware`, `XEventListener`, `XException` and `XEnum`.
- Order the actions of a controller and the abilities of its policy alike: `display`, `index`, `view`, `add`, `edit`, `delete`, then the others.

## Dependency injection

- Register table classes as services and pass them to their services with `addArgument()`.
- Never construct a service or call `fetchTable()` inside a service.
- Register middleware that has dependencies as a service and add it to the queue by class name.
- Let the container inject the dependencies of middleware through the constructor.
- Inject configuration with `#[Configure('Key.path')]` instead of calling `Configure` inside services.
- Bind each interface to a concrete class in one composition root; never bind an interface to an abstract class.
- Skip services for simple CRUD, entity methods, helpers and validation.

## ORM and queries

- Use integer primary keys.
- When a table needs UUID keys, generate UUIDv7 in the database (PostgreSQL 18+): default the column to `uuidv7()` and override `Table::_newId()` in the base table to return `null`, so that the ORM does not send a v4 UUID.
- Put repeated query conditions in custom finders on the table.
- Load associations with `contain()` instead of querying in loops; filter by an association with `matching()` or `innerJoinWith()`.
- Fetch required records with `get()` or `firstOrFail()` so that a missing record becomes a 404.
- Check the result of `save()` and `delete()`, or use `saveOrFail()` and `deleteOrFail()` in services.
- Put data-shape validation in `validationDefault()` and rules that need the database, such as `isUnique()` and `existsIn()`, in `buildRules()`.
- Soft-delete with `is_deleted`, filtered by a custom finder on every public read.
- Declare `jsonb` columns (PostgreSQL) `array|null` in entity docblocks and normalise empty values with a behaviour.
- Validate enum columns with `->enum()`.
- When writing a slug behaviour, guard a missing source value, generate the slug once and resolve collisions.
- Use the `Timestamp` behaviour with a nullable `modified`.
- Wrap multistep writes in `$connection->transactional()`.
- Allow-list sortable columns with the paginator's `sortableFields` option and cap page size with `maxLimit`.
- Call `parent::initialize($config)` in `initialize()` of tables and behaviours.

## Migrations

- Keep the default `id` primary key, which PostgreSQL 10+ creates as an identity column.
- For UUID keys, create the table with `['id' => false, 'primary_key' => 'id']` and an `id` column of type `uuid` defaulting to `Literal::from('uuidv7()')` (PostgreSQL 18+).
- Order table columns as `id` where present, data columns, foreign keys, `is_*` flags, `created` (defaulting to `CURRENT_TIMESTAMP`) and `modified`.
- Declare `created` and `modified` with `'timezone' => true` (PostgreSQL), so that they become `timestamptz`.
- Declare partial indexes with the `where` option (PostgreSQL).

## Errors and exceptions

- Carry context in `private readonly` promoted properties.
- Word messages as full sentences ending in a full stop.
- Document `@throws` on interfaces and implementations.

## Value objects, DTOs and integrations

- Model domain primitives as `final readonly` value objects that validate in the constructor and throw a validation exception.
- Never trim silently inside a value object.
- Give value objects `equals()` and `__toString()` where useful; build changed copies instead of mutating.
- Keep DTOs immutable and free of mapping logic.
- Isolate each external schema in one mapper that returns DTOs and rewraps validation failures from response data as an invalid-response exception.
- Depend on PSR interfaces at integration seams, wire collaborators in a factory and keep static mutable state out.

## Configuration and deployment

- Prefix cache keys with a namespace instead of bare identifiers.
- Deploy tagged releases built with `composer install --no-dev --optimize-autoloader`.
- Cast boolean environment values with `filter_var(..., FILTER_VALIDATE_BOOLEAN)`.

## Security

- Keep `role`, `is_verified`, `is_blocked` and `is_deleted` out of `_accessible`.
- Never pass unfiltered `$request->getData()` to `save()` or `patchEntity()`.
- Restrict the writable fields per action with the `accessibleFields` option.
- Pass user input to conditions only as array values or bound parameters; never in condition keys or raw SQL strings.
- Restrict state-changing actions with `$this->request->allowMethod()` and trigger them with `FormHelper::postLink()` or forms, never plain links.
- Never use a record id as an unguessable token; generate tokens with `Security::randomString()`.
- Hide sensitive entity fields, such as password digests and tokens, with `$_hidden`.
- Never set `'escape' => false` on helper output that contains user data.
- Keep `CsrfProtectionMiddleware` in the middleware queue and build forms with `FormHelper` so that the token is included.
- When the Authorization plugin is installed, never call `skipAuthorization()` in authenticated areas.
- Write policies and check ownership in them instead of ad-hoc `where` clauses.

## Templates and routing

- Declare `DashedRoute` routes with explicit HTTP methods, `setPass()` and slugs rather than ids in public URLs, because integer ids are enumerable.
- Build URLs and links from route arrays or named routes with `HtmlHelper`, `UrlHelper` and `Router::url()`, never hard-coded paths.
- Wrap user-facing strings in `__()` with English source text and add the project locale's translation.
- Put `label` first and `type` second in the options of `FormHelper::control()`.
- Keep `App.defaultTimezone` at UTC and convert to the display timezone only in views.

## Docblocks

- Specify event generics such as `EventInterface<Controller>`.
- On tables, declare `@property` associations and entity-typed `@method` overrides; on entities, declare every column with `@property`.

## Tests

- Mirror `src/` under `tests/TestCase/`, name classes `<Class>Test` and methods `testX`, and make test classes `final`.
- Write data providers that `yield 'descriptive key' => [...]`, and cover invalid-input matrices, including trailing newlines and boundary values.
- Assert booleans with `assertTrue()` and `assertFalse()`, as PHPStan requires.
- Test failures with `expectException()` and `expectExceptionMessage()`.
- Use `try`/`self::fail()`/`catch` when asserting exception context.
- Freeze time in tests with `DateTime::setTestNow()` instead of injecting a clock.

## Documentation

- The CakePHP 5.x Cookbook (https://book.cakephp.org/5.x/) is authoritative for framework behaviour; consult it before relying on memory.
