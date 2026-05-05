# Developer guide: production releases and versioning

This repository deploys production from **semver tags** (`vMAJOR.MINOR.PATCH`). Tags are created automatically when changes land on `main`, using **semantic-release** and [Conventional Commits](https://www.conventionalcommits.org/). **No GitHub Releases** are created — only **git tags** (see the repository **Tags** page).

**What semantic-release reads:** the **actual commit(s)** on `main` after merge — for squash merge, that is whatever appears in the **Squash and merge** commit message box in the GitHub UI (first line = subject), not the PR title unless you leave the default unchanged.

## What you need to do

### 1. Use squash merge into `main`

Merge with **Squash and merge**. Before you confirm, edit the **commit message** so the **first line** follows conventional commit format (see below). Reviewers approve the PR; they do **not** automatically enforce this message — whoever merges is responsible for the final text.

### 2. Conventional first line (subject) examples

| Intent | Example first line |
|--------|---------------------|
| New feature (minor bump) | `feat: add invoice export` |
| Bug fix (patch bump) | `fix: correct tax rounding` |
| Breaking change (major bump) | `feat!: remove legacy API` |
| Docs / chore only (often no release) | `docs: update README` — may not trigger a version bump |

Use types your team agrees on (`feat`, `fix`, `perf`, `refactor`, etc.). **Avoid** vague subjects like `Update stuff` — semantic-release may not produce a new tag, or the wrong bump may be inferred.

### Breaking changes (major version)

The analyzer uses the **Conventional Commits** preset so `feat!:` / `fix!:` in the **subject** counts as a breaking change.

- **Do not** use a squash message whose **only** line is `BREAKING CHANGE: …` — that belongs in the **body** after a blank line, under a normal header such as `feat: what changed`.
- Prefer subject: `feat!: what changed` (or `fix!: …`).
- Or subject `feat: what changed` and in the **extended description** (body): `BREAKING CHANGE: why it is breaking`.

## What happens in CI

1. **Merge to `main`** runs the **Release** workflow. It analyzes commits since the last tag and may create and push a new **git tag** (`vMAJOR.MINOR.PATCH`) only.
2. **Deploy (production)** runs automatically **after Release completes successfully**, finding the tag on the **same commit** as the merge that triggered Release (`workflow_run` + `--points-at`). Tag pushes made with the default `GITHUB_TOKEN` do **not** trigger other workflows; `workflow_run` handles deploy.
3. **Pushing a matching tag** in other ways (for example a personal access token or manual `git push`) can still trigger **Deploy (production)** via the tag `push` trigger.
4. **Manual redeploy**: open **Actions → Deploy (production) → Run workflow**. Under **Use workflow from**, switch the ref control from the default branch to **Tags** and pick the version (e.g. `v1.2.3`). The run must use a **tag ref**, not `main`, or deployment is skipped.

If you later configure semantic-release to use a **PAT** so tag pushes trigger workflows, a release could start both the **workflow_run** deploy and the **push** deploy for the same tag. In that case, remove the `workflow_run` trigger from **Deploy (production)** or accept redundant runs and rely on idempotent deploys.

**Note:** GitHub runs the workflow file **as it exists on that tag’s commit**. If deploy logic changed later on `main`, redeploying an old tag still uses the older workflow definition.

## Troubleshooting

- **No new tag after merge**: Usually only `feat`, `fix`, `perf`, `refactor`, and similar types trigger releases; pure `chore:` / `docs:` may not. Check the Release workflow logs on `main`.
- **Wrong version bump**: Fix comes from the **squashed commit message** you confirmed in GitHub. Use `feat!:` / `fix!:` in the subject, or `BREAKING CHANGE:` in the body **after** a normal `type: subject` line — not as the only line.
- **Manual run did not deploy**: Confirm **Use workflow from** is a **`vMAJOR.MINOR.PATCH` tag**, not a branch.

## Repo settings to confirm with maintainers

- Default merge style: **squash merge**; optionally **default squash message from PR title** to reduce editing, but the merger should still verify the final message.
- Branch protection: pull requests and **reviewers** required into `main` where policy applies; restrict direct pushes if that is policy.
