# Developer guide: production releases and versioning

This repository deploys production from **semver tags** (`vMAJOR.MINOR.PATCH`). Tags are created automatically when changes land on `main`, using **semantic-release** and [Conventional Commits](https://www.conventionalcommits.org/).

## What you need to do

### 1. Use squash merge into `main`

Merge your PR with **squash and merge** (team default). The squash commit message should follow conventions — usually it is taken from the **PR title**.

### 2. Set the PR title before merging

Rename the PR title so it matches conventional commit format, for example:

| Intent | Example title |
|--------|----------------|
| New feature (minor bump) | `feat: add invoice export` |
| Bug fix (patch bump) | `fix: correct tax rounding` |
| Breaking change (major bump) | `feat!: remove legacy API` (best for squash title) |
| Docs / chore only (often no release) | `docs: update README` — may not trigger a version bump |

Use types your team agrees on (`feat`, `fix`, `perf`, `refactor`, etc.). **Avoid merging** with vague titles like `Update stuff` — semantic-release may not produce a new tag, or the wrong bump may be inferred.

### Breaking changes (major version)

The analyzer uses the **Conventional Commits** preset so `feat!:` / `fix!:` in the **subject** counts as a breaking change.

- **Do not** make the squash message **only** `BREAKING CHANGE: …` — that token is a **footer**, not a header line, so the commit is treated as non-conventional and **no release** is produced.
- Prefer PR title: `feat!: what changed` (or `fix!: …`).
- Or: first line `feat: what changed` and a later line (or PR body, if squash includes it) with `BREAKING CHANGE: why it is breaking`.

### 3. Optional safety net

A workflow (`lint-pr-title`) validates the PR title against conventional commit rules. If it fails, adjust the title and push again.

## What happens in CI

1. **Merge to `main`** runs the **Release** workflow. It analyzes commits since the last tag and may create a new **Git tag** and GitHub Release.
2. **Deploy (production)** runs automatically **after Release completes successfully**, using the semver tag on that release commit. This is required because tag pushes made with the default `GITHUB_TOKEN` do **not** trigger other workflows on GitHub.
3. **Pushing a matching tag** in other ways (for example a personal access token or manual `git push`) can still trigger **Deploy (production)** via the tag `push` trigger.
4. **Manual redeploy**: open **Actions → Deploy (production) → Run workflow**. Under **Use workflow from**, switch the ref control from the default branch to **Tags** and pick the version (e.g. `v1.2.3`). The run must use a **tag ref**, not `main`, or deployment is skipped.

If you later configure semantic-release to use a **PAT** so tag pushes trigger workflows, a release could start both the **workflow_run** deploy and the **push** deploy for the same tag. In that case, remove the `workflow_run` trigger from **Deploy (production)** or accept redundant runs and rely on idempotent deploys.

**Note:** GitHub runs the workflow file **as it exists on that tag’s commit**. If deploy logic changed later on `main`, redeploying an old tag still uses the older workflow definition.

## Troubleshooting

- **No new tag after merge**: Usually only `feat`, `fix`, `perf`, `refactor`, and similar types trigger releases; pure `chore:` / `docs:` may not. Check the Release workflow logs on `main`.
- **Wrong version bump**: Fix comes from the **squashed commit message** (your PR title and optional body). Use `feat!:` / `fix!:` in the title, or `BREAKING CHANGE:` in the message **after** a normal `type: subject` line — not as the only line.
- **Manual run did not deploy**: Confirm **Use workflow from** is a **`vMAJOR.MINOR.PATCH` tag**, not a branch.

## Repo settings to confirm with maintainers

- Default merge style: **squash merge**, with squash message derived from **PR title** (GitHub repository setting).
- Branch protection: pull requests required into `main`; no direct pushes if that is policy.
