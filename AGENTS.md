# AGENTS.md — CI/CD + Pre-commit + Semantic Release brief for Codex (GPT-5)

## 🎯 Goal
This repository hosts an **Ansible Collection**.
The pipeline must:
1. **Run fast local pre-commit hooks** (`ansible-lint` + `yamllint`) before committing.
2. **Enforce in CI** on every push/MR: `ansible-lint` + `molecule test --all` (docker driver).
3. **Use Semantic Release** on `main` to version automatically following Conventional Commits.
4. **Build + publish** on tags `vX.Y.Z`.
5. **Mirror** this repo **read-only to GitHub** on `main` and on **all tags**.
6. **Upload certified releases to Red Hat Automation Hub** via `REDHAT_PARTNER_TOKEN`.

GitLab is the **source of truth**; GitHub is the **public mirror**.

---

## ✅ Local developer setup (pre-commit)
Install and enable hooks:
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
ansible-lint

# Or run the curated container (builds automatically)
./scripts/test-container.sh
```
After **every change**, rerun `./scripts/test-container.sh` until it completes without errors.
Configured in `.pre-commit-config.yaml`:
- **ansible-lint** (with `ansible` dependency)
- **yamllint** (line-length ≤ 120)

> Keep local hooks fast — full Molecule runs stay in CI.

---

## 🔧 CI / Semantic Release workflow

| Stage | Trigger | Purpose |
|-------|---------|---------|
| **lint + test** | any branch push/MR | `ansible-lint`, `molecule test --all` |
| **semantic_release** | pushes to `main` with Conventional Commits | `npx semantic-release` → patches `VERSION`, `galaxy.yml`, README, tags `vX.Y.Z` |
| **semantic_version_check** | before build | ensures git tag = `galaxy.yml` version = `VERSION` |
| **build + publish** | on tags `^v\d+\.\d+\.\d+$` | `ansible-galaxy collection build`, publish to Galaxy & Hub |
| **publish_automation_hub** | on tags `^v\d+\.\d+\.\d+$` | upload the same tarball to Red Hat Partner Connect |
| **mirror_to_github** | on `main` and tags | mirror to GitHub (read-only) |

---

### 🔐 Required CI Variables (Protected + Masked)
| Variable | Purpose |
|----------|---------|
| `GL_TOKEN` / `GL_TOKEN` | GitLab PAT (api scope) for semantic-release |
| `GALAXY_TOKEN` | https://galaxy.ansible.com/ui/token/ |
| `GITHUB_TOKEN` | GitHub PAT (repo scope) for mirroring |
| `REDHAT_PARTNER_TOKEN` | Partner Connect API key for Automation Hub uploads |
| `SEMVER_GIT_USER_NAME`, `SEMVER_GIT_USER_EMAIL` | Optional release identity |

---

## 🧪 Acceptance Criteria
- Pre-commit runs locally for all contributors.
- CI blocks merges if lint/tests fail.
- Conventional Commits merged to `main` trigger Semantic Release → tag `vX.Y.Z` + metadata sync.
- Tagged pipeline builds, publishes to Galaxy **and** uploads to Red Hat Partner Connect.
- `./scripts/test-container.sh` passes before pushing changes.

---

## 📚 Official Reference Checklist
Based on **Red Hat Partner Connect Ansible Certification Workflow** and the **Ansible Developer Guide**.

### 🔎 Key Requirements
- Collection layout must follow the official structure (`galaxy.yml`, `roles/`, optional `plugins/`).
- `galaxy.yml` must include namespace, name, version, license, readme, authors, repository, issues.
- List supported platforms under `galaxy_info/platforms`.
- Declare dependencies in `requirements.yml` with versions.
- Run `ansible-lint --profile production` with zero errors before certification.
- Provide Molecule scenarios (Docker driver) for each role.
- `ansible-galaxy collection build` must succeed producing `<namespace>-<name>-<version>.tar.gz`.
- Upload same tarball to Galaxy and Red Hat Partner Connect.
- Use CI guardrails: lint/tests on all refs; build/publish only on release tags.

### Sources
- Red Hat Partner Connect — *Ansible Certification Workflow Guide*
- Ansible Developer Guide — *Developing Collections*
