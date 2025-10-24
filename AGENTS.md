# AGENTS.md — CI/CD + Pre‑commit + Semantic Release brief for Codex (GPT‑5)

## 🎯 Goal
This repository hosts an **Ansible Collection**.  
The pipeline must:
1. **Run fast local pre‑commit hooks** (`ansible-lint` + `yamllint`) before committing.  
2. **Enforce in CI** on every push/MR: `ansible-lint` + `molecule test --all` (docker driver).  
3. **Use Semantic Release** on `main` to version automatically following Conventional Commits.  
4. **Build + publish** on tags `vX.Y.Z`.  
5. **Mirror** this repo **read‑only to GitHub** on `main` and on **all tags**.  
6. **Upload certified releases to Red Hat Automation Hub** via `REDHAT_PARTNER_TOKEN`.

GitLab is the **source of truth**; GitHub is the **public mirror**.

---

## ✅ Local developer setup (pre‑commit)
Install and enable hooks:
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
# must pass ansible-lint locally before pushing
ansible-lint
```
Configured in `.pre-commit-config.yaml`:
- **ansible-lint** (with `ansible` dependency)  
- **yamllint** (line‑length ≤ 120)

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
| **mirror_to_github** | on `main` and tags | `git push --mirror` to GitHub (read‑only) |

---

### 🔐 Required CI Variables (Protected + Masked)
| Variable | Purpose |
|----------|---------|
| `GL_TOKEN` / `GITLAB_TOKEN` | GitLab PAT (api scope) for semantic‑release |
| `GALAXY_TOKEN` | From https://galaxy.ansible.com/ui/token/ |
| `GITHUB_TOKEN` | GitHub PAT (repo scope) for mirroring |
| `REDHAT_PARTNER_TOKEN` | Partner Connect API key for Automation Hub uploads (required) |
| `SEMVER_GIT_USER_NAME`, `SEMVER_GIT_USER_EMAIL` | Optional: override release commit identity |

---

## 🧪 Acceptance Criteria
- ✅ Pre‑commit runs locally for all contributors.  
- ✅ CI blocks merges if lint/tests fail.  
- ✅ Conventional Commits merged to `main` trigger Semantic Release → tag `vX.Y.Z` + metadata sync.  
- ✅ Tagged pipeline builds, publishes to Galaxy **and** uploads to Red Hat Partner Connect for certification, then mirrors `main` + tags to GitHub (read‑only).

---

## 📚 Official Reference Checklist
Based on **Red Hat Partner Connect Ansible Certification Workflow** and the **Ansible Developer Guide — Developing Collections**.

### 🔎 Key Requirements
- The collection directory structure must follow the official layout with `galaxy.yml`, `roles/`, optional `plugins/` or `modules/`.  
- `galaxy.yml` must include: `namespace`, `name`, `version`, `license`, `readme`, `authors`, `repository`, `issues`.  
- RHEL platforms supported: list under `galaxy_info/platforms`.  
- Your `requirements.yml` should list dependent collections with version constraints.  
- Run `ansible-lint --profile production` and ensure zero errors before certification.  
- Optionally run `ansible-test sanity` for plugins/modules.  
- Provide `molecule/default/` scenarios for each role; use Docker driver for CI.  
- `ansible-galaxy collection build` must succeed and produce `<namespace>-<name>-<version>.tar.gz`.  
- Upload the same tarball to **Galaxy** and to **Red Hat Partner Connect** (Automation Hub certification).  
- Versioning follows SemVer; releases are tagged `vX.Y.Z` and are immutable once published.  
- Use CI to guard all of the above: lint/tests on all refs; build/publish only on release tags; mirror repository accordingly.
- Treat `ansible-lint` failures as blockers — rerun locally before every push/merge request.

### Sources
- Red Hat Partner Connect — *Ansible Certification Workflow Guide* (PDF)  
  https://connect.redhat.com/sites/default/files/2025-06/Ansible-Certification-Workflow-Guide202506.pdf
- Ansible Developer Guide — *Developing Collections*  
  https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html
- Ansible Developer Guide — *Collection Creator Path*  
  https://docs.ansible.com/ansible/latest/dev_guide/developing_collections_path.html
