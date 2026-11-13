---
paths:
  - "**/*.dockerfile"
  - "**/.dockerignore"
  - "**/compose*.{yml,yaml}"
  - "**/docker-compose*.{yml,yaml}"
  - "**/Dockerfile*"
---

# Docker

## Images

- Pin every pulled image, including images in `COPY --from`, to an exact version and base distribution, such as `nginx:<version>-alpine<version>`; never use `latest`.
- Pin extensions installed during the build, such as `pecl install redis-<version>`.
- Start Dockerfiles with `# syntax=docker/dockerfile:1`.
- Start a `RUN` of several commands with `set -eux`, so that the build stops at the first failure.
- Use multi-stage builds so that build tools stay out of the final image.
- Use `COPY`, not `ADD`, for files from the build context.
- Pass build secrets with `RUN --mount=type=secret`, never through `ARG` or `ENV`.
- Run the final stage as a non-root `USER` unless the service starts as root and drops privileges itself, as nginx does for its worker processes.
- Take a tool's binary from its official image with `COPY --from` instead of running a download script.
- On Alpine, install build dependencies as a `--virtual` package group and remove them, with caches, in the same `RUN`.
- Ignore everything in `.dockerignore` and allow only the files the build needs.

## Compose

- Mount configuration files and code that a service only reads with `:ro`.
- Keep persistent data in named volumes.
- Add a `healthcheck` where it is beneficial, such as for a service that another one needs ready, and wait for it with `condition: service_healthy`.
- Write a `healthcheck` test in the exec form (`["CMD", …]`) and address `127.0.0.1`, not `localhost`.
- Publish a port only when the host needs it; services reach each other over the Compose network.
- Publish development ports on the loopback address, such as `127.0.0.1:8080:80`, because a published port otherwise listens on all interfaces and bypasses firewalls such as ufw.
- Read credentials and environment-specific values from the env file through `${VARIABLE}`.

## Tool services

- Suggest a one-shot tool, such as Node.js for npm, as a service of its own where it adds value, such as to avoid installing the tool on the host; do not add one unasked.
- Put a tool service under a profile, such as `profiles: ["tools"]`, so that it does not start with the stack.
- Give it `init: true`, the project mounted as its working directory and a named volume for the tool's cache.
- Give it no `container_name` or `restart`.
