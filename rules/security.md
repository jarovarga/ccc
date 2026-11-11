# Security

## Principles

- Grant only the access that a user, service, token, file or database role needs to perform its task.
- Treat every external input, client and system as untrusted until it is verified, even inside an internal network: check input at each tier and never rely on client-side access checks.
- Do not rely on a single control; layer controls so that the others still protect when one fails.
- Make the secure option the default; expose or enable only what is needed: deny by default when new functionality or resources are exposed, and make every grant an explicit choice.
- On failure, fall back to a secure state: return a generic response and log the details on the server; never disclose sensitive information in errors.
- Protect sensitive data by encrypting it in transit and at rest.
- Do not share or publish private project content outside the repository and the services the task names.
- Collect and keep only the personal data that the task needs.
- Do not weaken or remove a security control of the code to make a feature or test pass; fix the cause or ask.

## Credentials

- Never read, copy, print or modify credentials, wherever they are:
  - private keys and certificates, including any file that contains a private key;
  - the credential files of package registries, cloud providers and network clients;
  - environment files that hold secrets, such as `.env`;
  - the full environment of a process or shell, which can hold secrets.
- Apply this to indirect access as well: do not reach these credentials through searches, scripts or other commands that open files themselves.
- Let the tools that need credentials load them, rather than reading and passing them on.
- Add a new environment variable to the project's example environment file with a placeholder value only.
- Never store secrets in source, configuration, fixtures or commits; keep them in secure storage and use placeholders for real credentials and sensitive data.
- Keep secrets out of command arguments, which other processes can read; pass them through stdin, a file with restrictive permissions or an environment variable the tool reads.
- Generate security-relevant random values with a cryptographically secure generator and compare secrets in constant time.
- Never write secrets or personal data to logs.
- Redact secrets and sensitive data before sharing output.
- If a secret is found exposed, report it and treat it as compromised: it must be revoked, not only removed.

## Dependencies

- Commit lock files and never use wildcard or development-branch version constraints.
- Deploy from the lock file without development dependencies.
- Pin external artefacts, such as container images and downloaded tools, to an exact version.
- Run the project's dependency audit after changing dependencies, if the project defines one.
- Before adding a dependency, check that the package exists in the official registry and is the intended one, by its name and its publisher or repository; never add a package name from memory.
- Do not install, enable or run unreviewed plugins, extensions, servers or downloaded scripts, and never pipe downloaded content into a shell.

## Services and files

- Do not disable TLS certificate or hostname verification in any client, library or tool; never commit or deploy such a setting.
- Bind development services to the loopback address (`127.0.0.1`) instead of all interfaces.
- Give files and directories the most restrictive permissions that work; never make them world-writable.
