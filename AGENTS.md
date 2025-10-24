# AGENTS.md — CI/CD + Pre-commit brief for Codex (GPT‑5)

## 🎯 Goal
For this Ansible Collection repository:
1. **Run local pre-commit hooks** for fast feedback (ansible-lint + yamllint) before committing.
2. **Enforce in CI on every push/MR**: `ansible-lint` + `molecule test --all` (docker driver).
3. **Build & publish on SemVer tags only** matching `vX.Y.Z`.
4. **Mirror read-only to GitHub** on pushes to `main` and on **all tags**.

GitLab is the source of truth. GitHub is a public read-only mirror.
Optional: publish to Red Hat Automation Hub if `REDHAT_PARTNER_TOKEN` is set.

---

## ✅ Local developer setup (pre-commit)
Add and enable pre-commit hooks:
```bash
pip install pre-commit
pre-commit install
# one-time full run on the repo
pre-commit run --all-files
```
Pre-commit hooks (configured in `.pre-commit-config.yaml`):
- **ansible-lint** (with `ansible` as dependency)
- **yamllint** (line-length relaxed to 120)

> Keep pre-commit fast. Full Molecule runs stay in CI.

---

## 🔧 CI (.gitlab-ci.yml)
- Lint + Molecule on **every** push/MR (all branches incl. `main`).
- `semantic_release` runs on default-branch pushes; it executes `npx semantic-release`, which (via `@semantic-release/exec`) patches `VERSION`, `galaxy.yml`, and the README before committing and tagging.
- **Build + publish only on tags** `^v\d+\.\d+\.\d+$`.
- `semantic_version_check` job ensures the git tag matches `galaxy.yml` version before build/publish.
- `VERSION` file must match `galaxy.yml` version; pipeline will fail if mismatch.
- Mirror to GitHub on **main** and **all tags**.

Required CI variables (Protected + Masked):
- `GL_TOKEN` (or `GITLAB_TOKEN`) — GitLab PAT with `api` scope for semantic-release
- `GALAXY_TOKEN` — https://galaxy.ansible.com/ui/token/
- `GITHUB_TOKEN` — GitHub PAT with `repo` scope
- `REDHAT_PARTNER_TOKEN` *(optional)* — Automation Hub upload
- `SEMVER_GIT_USER_NAME` / `SEMVER_GIT_USER_EMAIL` *(optional)* — override release commit identity supplied to semantic-release

---

## 🧪 Acceptance
- Pre-commit runs locally for all contributors.
- CI blocks merges if lint/tests fail.
- Conventional Commits merged to `main` trigger semantic-release, which creates the next `vX.Y.Z` tag and keeps repo metadata in sync.
- GitHub mirror updates on `main` and on tags (read-only).
