# Guidelines for Automated Agents

This document defines the expectations for any AI or automation agent interacting with the Ansible collection repositories.

## Golden Rules

1. **Stay reproducible.** Every change must be backed by an automated lint/test command (see the shared pipeline template). If the pipeline would fail, the change should not be proposed.
2. **Keep edits minimal.** Touch only the files required for the change. Mechanical updates (formatting, generated files) should be clearly stated in the commit message.
3. **Explain the change.** Every merge request must explain why the change is needed, what parts of the repository are affected, and how the effect was validated.
4. **Respect the licensing.** Use the shared `LICENSE` verbatim. Do not introduce dependencies that are incompatible with Apache 2.0 without human approval.
5. **No secrets, ever.** Never commit credentials, tokens, or production configuration. Use the documented CI/CD variables only.

## Workflow Checklist

- [ ] Run `pre-commit run --all-files` before opening a merge request.
- [ ] Run `molecule test` (or the equivalent job from the shared pipeline) when roles are changed.
- [ ] Ensure `galaxy.yml` version increments only come from semantic-release.
- [ ] Update documentation (`README`, changelog, release notes) when behaviour changes.
- [ ] For cross-repo changes, update the canonical files in `shared-assets` first, then sync downstream repositories.

## Communication

When opening a merge request, include:

- A short summary describing the change.
- Links to the relevant issue or discussion.
- Any manual validation steps that humans may need to repeat (if automation is not yet available).

If the agent cannot complete the checklist (for example the pipeline is red or manual intervention is needed), it must label the merge request with `needs-human` and assign the repository maintainers.

## Violation Handling

Repeated violations (for example pushing without running tests or altering protected files) will cause the agent’s user or API token to be revoked. Keep the automation reliable so humans can trust its output.

---

_This file is managed centrally in `shared-assets`. Do not edit downstream copies directly; propose changes here so every repository inherits the update._
