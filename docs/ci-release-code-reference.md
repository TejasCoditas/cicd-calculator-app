# CI release and prod deploy — code reference

Add or align the following in the repository. Production branch is assumed to be `main`.

## `package.json` (`devDependencies`)

```json
{
  "@semantic-release/commit-analyzer": "^13.0.0",
  "@semantic-release/github": "^11.0.0",
  "@semantic-release/release-notes-generator": "^14.0.0",
  "semantic-release": "^24.0.0"
}
```

Then run:

```bash
npm install
```

## `.releaserc.json` (repository root)

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/github",
      {
        "successComment": false,
        "releasedLabels": false
      }
    ]
  ]
}
```

## `.github/workflows/release.yml`

```yaml
name: Release (semantic version tag)

run-name: Release on main ${{ github.sha }}

on:
  push:
    branches:
      - main

permissions:
  contents: write
  issues: write
  pull-requests: write

concurrency:
  group: release-main
  cancel-in-progress: false

jobs:
  release:
    name: Tag release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: true

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Semantic release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: npx semantic-release
```

## `.github/workflows/lint-pr-title.yml`

```yaml
name: Lint PR title

on:
  pull_request:
    types:
      - opened
      - edited
      - synchronize
      - reopened

permissions:
  pull-requests: read
  statuses: write

jobs:
  validate:
    name: Conventional PR title
    runs-on: ubuntu-latest
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## `.github/workflows/deploy-prod.yml`

```yaml
name: Deploy (production)

# - Tag push: deploy that tag (e.g. tag pushed with a PAT or outside Actions).
# - workflow_run: after Release workflow — required when semantic-release uses GITHUB_TOKEN (tag pushes do not trigger workflows).
# - Manual: workflow_dispatch with "Use workflow from" set to a vX.Y.Z tag (not a branch).
run-name: Deploy prod ${{ github.ref_name }}

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
  workflow_run:
    workflows:
      - Release (semantic version tag)
    types:
      - completed
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: deploy-prod
  cancel-in-progress: false

jobs:
  verify:
    name: Verify branch
    runs-on: ubuntu-latest
    outputs:
      should_deploy: ${{ steps.check.outputs.should_deploy }}
      deploy_ref: ${{ steps.check.outputs.deploy_ref }}
      deploy_tag: ${{ steps.check.outputs.deploy_tag }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check if deploy should run
        id: check
        env:
          RELEASE_HEAD_SHA: ${{ github.event_name == 'workflow_run' && github.event.workflow_run.head_sha || '' }}
          RELEASE_CONCLUSION: ${{ github.event_name == 'workflow_run' && github.event.workflow_run.conclusion || '' }}
        run: |
          set -euo pipefail

          write_outputs() {
            echo "should_deploy=$1" >> "${GITHUB_OUTPUT}"
            echo "deploy_ref=${2:-}" >> "${GITHUB_OUTPUT}"
            echo "deploy_tag=${3:-}" >> "${GITHUB_OUTPUT}"
          }

          if [[ "${GITHUB_EVENT_NAME}" == "workflow_run" ]]; then
            if [[ "${RELEASE_CONCLUSION:-}" != "success" ]]; then
              echo "::notice::Release workflow finished with '${RELEASE_CONCLUSION:-unknown}' — skipping deploy."
              write_outputs false
              exit 0
            fi
            HEAD_SHA="${RELEASE_HEAD_SHA:-}"
            if [[ -z "${HEAD_SHA}" ]]; then
              echo "::warning::workflow_run missing head SHA — skipping deploy."
              write_outputs false
              exit 0
            fi
            git fetch origin main --tags
            candidates="$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --points-at "${HEAD_SHA}")"
            if [[ -z "${candidates}" ]]; then
              echo "::notice::No vMAJOR.MINOR.PATCH tag on the release commit — semantic-release did not publish a version. Skipping deploy."
              write_outputs false
              exit 0
            fi
            tag="$(echo "${candidates}" | sort -V | tail -1)"
            git fetch origin main
            if ! git merge-base --is-ancestor "${HEAD_SHA}" origin/main; then
              echo "::warning::Release commit is not on main — skipping deployment."
              write_outputs false
              exit 0
            fi
            write_outputs true "refs/tags/${tag}" "${tag}"
            exit 0
          fi

          if [[ "${GITHUB_REF}" == refs/tags/* ]] && {
            [[ "${GITHUB_EVENT_NAME}" == "push" ]] || [[ "${GITHUB_EVENT_NAME}" == "workflow_dispatch" ]]
          }; then
            tag="${GITHUB_REF_NAME}"
            git fetch origin main
            if [[ ! "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
              echo "::warning::Production tag must be vMAJOR.MINOR.PATCH (digits only, e.g. v1.0.0). Got: ${tag}"
              write_outputs false
              exit 0
            fi
            if ! git merge-base --is-ancestor "${GITHUB_SHA}" origin/main; then
              echo "::warning::Tag ${tag} does not point to a commit on main — skipping deployment."
              write_outputs false
              exit 0
            fi
            write_outputs true "${GITHUB_REF}" "${tag}"
            exit 0
          fi

          if [[ "${GITHUB_EVENT_NAME}" == "workflow_dispatch" ]]; then
            echo "::warning::Manual production deploy must be started from a version tag. In Actions, use 'Run workflow' and set 'Use workflow from' to a tag such as v1.2.3 (not the default branch). Ref: ${GITHUB_REF}"
            write_outputs false
            exit 0
          fi

          echo "::warning::Unsupported event or ref for production deploy: ${GITHUB_EVENT_NAME} ${GITHUB_REF}"
          write_outputs false

  deploy:
    needs: verify
    if: needs.verify.outputs.should_deploy == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ needs.verify.outputs.deploy_ref }}
          fetch-depth: 0

      - name: Deploy
        env:
          DEPLOY_TAG: ${{ needs.verify.outputs.deploy_tag }}
        run: |
          set -euo pipefail
          echo "Add production deploy steps for ${DEPLOY_TAG}"
```

`deploy-prod.yml` `workflow_run.workflows` must match `release.yml` top-level `name` exactly (`Release (semantic version tag)`).

Replace the `Deploy` step with real production deploy commands.
