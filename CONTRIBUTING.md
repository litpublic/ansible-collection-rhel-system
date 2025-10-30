# Contributing to Lightning IT Ansible Collections

Thanks for taking the time to contribute! These guidelines keep every collection consistent and make reviews fast.

## Ground Rules

1. **Automate everything you can.** Run the shared pre-commit hooks (`pre-commit run --all-files`) and ensure the GitLab pipeline is green before asking for review.
2. **Keep changes scoped.** Focus each merge request on a single fix or feature. Avoid opportunistic refactors unless they are part of the change description.
3. **Document behaviour.** Update READMEs, role docs, and changelog entries when functionality changes. Explain _why_ as well as _what_.
4. **Stick to the licence.** All contributions are Apache 2.0. Make sure new dependencies are licence-compatible and documented in `requirements.yml` where relevant.
5. **No secrets or customer data.** Never commit credentials, tokens, or production configuration. Use CI variables and vaults instead.

## Workflow Checklist

- [ ] Branch from `main` (or apply the shared release strategy when tagging).
- [ ] Run `pre-commit install` once per clone, then `pre-commit run --all-files`.
- [ ] Execute `molecule test --all` when modifying roles, modules, or plugins.
- [ ] Validate `ansible-galaxy collection build` if you touch `galaxy.yml` or metadata.
- [ ] Update `CHANGELOG.md` or release notes when user-facing behaviour changes.
- [ ] Add or adjust automated tests where applicable.

## Merge Request Expectations

Each MR should include:

- A concise title following conventional commits (e.g. `fix: address lint failures`).
- A description covering the problem, solution, and validation steps.
- Links to related issues or epics.
- Screenshots or logs when relevant (for example, rendering changes or failure output).

## Release Process Highlights

- Semantic release handles version bumps. Only tag releases through the CI pipeline.
- Galaxy/Automation Hub publishing jobs require the cleaned build artifacts produced by the pipeline; do not upload local builds.
- Use the shared `rollout-ansible-collections` bot to push repository collateral updates (licence, guides, pre-commit config).

## Getting Help

- Raise questions in the project issue tracker.
- For urgent matters reach the Platform Engineering team in the `#automation` Slack channel.

---

_This file is managed in `shared-assets`. Downstream repositories should not edit their copy directly—propose changes here so every collection stays aligned._
