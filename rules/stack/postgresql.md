---
paths:
  - "**/*.sql"
---

# PostgreSQL

These rules apply where the project's database is PostgreSQL. The target version is the one the project declares, such as the image tag in its Compose file. A rule marked with a minimum version, such as (18+), applies from that version.

## Types and schema

- Use `timestamptz`, never `timestamp` or `timetz`.
- Set `timezone = 'UTC'` on the database or connection.
- Truncate fractional seconds with `date_trunc('second', …)`, not `timestamptz(0)`.
- Use `text` by default.
- Use `varchar(n)` only when the limit is a real domain rule, such as an email at 254 characters, with application validation equal to the limit.
- Never use `char(n)`.
- Use `numeric` or integers, never `money`.
- Use identity columns, never `serial`.
- Use `jsonb` for JSON.
- Generate UUID primary keys with `uuidv7()` (18+), not `gen_random_uuid()`.
- Write `STORED` or `VIRTUAL` (18+) explicitly on generated columns, because PostgreSQL 18 changed the default to `VIRTUAL`.
- Prefer generated columns to triggers for derived values.

## Constraints

- Use `UNIQUE NULLS NOT DISTINCT` (15+) when NULLs must collide.
- Enforce case-insensitive uniqueness, such as for emails, with a unique index on `lower(column)`.
- Prevent overlapping ranges with `WITHOUT OVERLAPS` (18+) on the primary or unique key instead of triggers; before 18, use an `EXCLUDE` constraint.
- Use triggers only for cross-row rules that a `CHECK` cannot express.
- Keep `CHECK` constraints and application enum values identical.

## Indexes

- On live tables create indexes with `CREATE INDEX CONCURRENTLY IF NOT EXISTS <name>`, outside a transaction block and in its own migration step.
- Drop the invalid index that a failed concurrent build leaves before retrying, because `IF NOT EXISTS` skips it.
- Use partial indexes for filtered reads.

## Migrations

- On live tables add `CHECK`, foreign key and `NOT NULL` (18+) constraints as `NOT VALID` and run `VALIDATE CONSTRAINT` in a separate step.
- Set `lock_timeout` in migrations that take strong locks so that they fail fast instead of queuing behind long transactions.

## Queries

- Select explicit columns, never `SELECT *`.
- Use `NOT EXISTS` instead of `NOT IN` with a subquery.
- Use `>=` with `<` instead of `BETWEEN` for time ranges.
- Paginate large or frequently changing result sets by key (`WHERE id > $last ORDER BY id LIMIT n`), not `OFFSET`.
- Use `INSERT … ON CONFLICT` for upserts.
- Use `RETURNING`, including `OLD` and `NEW` (18+), instead of a second query.
