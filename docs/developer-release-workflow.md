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
| Breaking change (major bump) | `feat!: remove legacy API` or put `BREAKING CHANGE:` in the PR body |
| Docs / chore only (often no release) | `docs: update README` — may not trigger a version bump |

Use types your team agrees on (`feat`, `fix`, `perf`, `refactor`, etc.). **Avoid merging** with vague titles like `Update stuff` — semantic-release may not produce a new tag, or the wrong bump may be inferred.

### 3. Optional safety net

A workflow (`lint-pr-title`) validates the PR title against conventional commit rules. If it fails, adjust the title and push again.

## What happens in CI

1. **Merge to `main`** runs the **Release** workflow. It analyzes commits since the last tag and may create a new **Git tag** and GitHub Release.
2. **Pushing a matching tag** runs **Deploy (production)** for that version.
3. **Manual redeploy**: use **Actions → Deploy (production) → Run workflow**. Leave **tag** empty to redeploy the **latest** `v*` tag on `main`, or enter a specific tag (e.g. `v1.2.3`).

## Troubleshooting

- **No new tag after merge**: Usually only `feat`, `fix`, `perf`, `refactor`, and similar types trigger releases; pure `chore:` / `docs:` may not. Check the Release workflow logs on `main`.
- **Wrong version bump**: Fix comes from the **squashed commit message** (your PR title). Use `feat!:` or `BREAKING CHANGE:` for majors.
- **Redeploy without a new merge**: Run **Deploy (production)** manually with an empty tag (latest on `main`) or a specific tag.

## Repo settings to confirm with maintainers

- Default merge style: **squash merge**, with squash message derived from **PR title** (GitHub repository setting).
- Branch protection: pull requests required into `main`; no direct pushes if that is policy.
