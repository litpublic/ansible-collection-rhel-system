# litpublic.rhel_system (v0.1.2)

Prefix-free role names:

- `baseline` — basic packages, time sync, journald/sshd sane defaults
- `hardening` — CIS-ish hardening controls (minimal demo)
- `podman` — Podman installation & registries.conf basics
- `firewall` — firewalld service enablement and example rules

> Collection scope: **OS-level** configuration for RHEL 8/9. Cluster/app config via **GitOps**.

`firewalld_manage_service` can be set to `false` (default `true`) when running in environments where the firewalld
service should not be managed directly (e.g., Molecule docker driver).

Community note: contributors and users are expected to follow the [Ansible Community Code of Conduct](CODE_OF_CONDUCT.md).

## Syncing shared assets

Need the shared scripts locally before CI runs? Fetch them with:

```bash
curl -fsSL https://gitlab.com/lit4/modulix/platform/software-development-ecosystem/automation-tools/shared-assets/-/raw/main/collections/common/scripts/sync_shared_assets.sh | bash
```

## Shared assets

This repository keeps only the collection-specific code. CI synchronises all common files
(CI config, lint/test scripts, Molecule scaffolding, etc.) from the `shared-assets` project.
Run the command above if you need them locally ahead of the CI sync job.

## CI/CD

- Pre-commit (`.pre-commit-config.yaml`) runs `ansible-lint` and `yamllint` locally. Install with `pip install pre-commit && pre-commit install`.
- `.gitlab-ci.yml` enforces `ansible-lint` and `molecule test --all` (docker driver) on every push/MR.
- `semantic_release` (default-branch pushes) runs `npx semantic-release`; via the official `@semantic-release/exec` plugin it patches `VERSION`, `galaxy.yml`, and the README to the new SemVer before tagging and committing (see `.releaserc.json`).
- `semantic_version_check` ensures the `galaxy.yml` version aligns with the `vX.Y.Z` git tag before build/publish jobs fire.
- The `VERSION` file must mirror the `galaxy.yml` version; CI blocks releases if they diverge.
- Tag releases as `vX.Y.Z` to build and publish to Ansible Galaxy automatically (requires protected `GALAXY_TOKEN`).
- Optional Automation Hub publishing runs when `REDHAT_PARTNER_TOKEN` is supplied.
- A `mirror_github` job pushes `main` and tags to the GitHub read-only mirror (`GITHUB_TOKEN`, `GITHUB_MIRROR_URL`).
- Local parity: run `./scripts/test-container.sh` to execute pre-commit, ansible-lint, and Molecule inside the curated container image.

Required CI variables (protected + masked):

- `GALAXY_TOKEN` (https://galaxy.ansible.com/ui/token/)
- `GL_TOKEN` (or `GITLAB_TOKEN`) — Personal Access Token with `api` scope for semantic-release
- `GITHUB_TOKEN` and `GITHUB_MIRROR_URL` (PAT with `repo` scope, e.g. `https://oauth2:${GITHUB_TOKEN}@github.com/lightning-it/ansible-collection-rhel_system.git`)
- `REDHAT_PARTNER_TOKEN` *(optional, Automation Hub)*
- `SEMVER_GIT_USER_NAME` / `SEMVER_GIT_USER_EMAIL` *(optional override for release commits; defaults baked into runner image)*

Example release trigger:

```bash
git commit -am "feat: expand hardening defaults"
git push origin main
```

Once merged to `main`, semantic-release publishes the next `vX.Y.Z` tag automatically; the tag pipeline then builds and publishes the collection artifacts.

