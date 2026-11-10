# Homebrew rename preparation (#14)

Status: prepared, not published. No acceptance box is closed by this receipt.

## Candidate and compatibility

- Issue: https://github.com/qubrics/homebrew-tap/issues/14; parent https://github.com/qubrics/qubrics/issues/894, spec A10/A12/A14.
- Base: `c9ebc138487f85c590a63edd570a803d82c8968b`, already live through [PR16](https://github.com/qubrics/homebrew-tap/pull/16). Its [main CI](https://github.com/qubrics/homebrew-tap/actions/runs/42766738138) passed but tested the legacy formula, not the Qubrics formula.
- The unchanged canonical formula installs public `@qubrics/cli@2.0.0` from `https://registry.npmjs.org/@qubrics/cli/-/cli-2.0.0.tgz`. Independent public download on 10 November produced SHA256 `2431314e4e3d4e485b5935a6b74921c09f005e82ebb4bab519d77c6d8911a799`, matching the formula. Public package metadata declares both `qubrics` and `sendmux` launchers and exact dependency `@qubrics/sdk@3.0.0`.
- `formula_renames.json` maps `sendmux` to `qubrics`; `Aliases/sendmux` points to `../Formula/qubrics.rb`. Remove the separate old formula so Homebrew migrates existing installs rather than installing conflicting packages. Canonical sources: [rename guidance](https://github.com/Homebrew/brew/blob/main/docs/Rename-A-Formula.md), [aliases](https://github.com/Homebrew/brew/blob/main/docs/Formula-Cookbook.md#a-quick-word-on-naming).
- Deprecation applies to the old name. README points to `qubrics`, and the CLI retains its own old-command warning for one major. Applying `deprecate!` to the shared formula would also deprecate the replacement.
- README and CI use `qubrics/tap/qubrics`. CI retains installation and formula tests, adds explicit version readback and permits a manual fresh-runner readback at cutover.

## Measured preparation

Measured 10 November 2026, before cutover:

| Check | Result |
| --- | --- |
| Existing old-name metadata | `brew info --json=v2 qubrics/tap/sendmux` resolves separate `sendmux` 1.7.1, no aliases or oldnames, not deprecated. Compatibility migration is not live yet. |
| Local installed baseline | `brew list --versions node node@24 sendmux qubrics`: existing `sendmux 1.3.1`; no `qubrics` installed. |
| Whitespace, workflow YAML, JSON syntax, alias target | Passed with `git diff --check`, Ruby YAML parsing, `jq empty`, `test -f` and `readlink`. |
| Offline strict audit | `HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict qubrics/tap/qubrics` exited 0 against the unchanged published 2.0.0 formula. |
| Formula style | `HOMEBREW_NO_AUTO_UPDATE=1 brew style Formula/qubrics.rb` exited 0: `1 file inspected, no offenses detected`. Homebrew emitted a vendor `rubocop-md` obsolete-option warning, not a formula offence. |
| Online audit | Exited 1: `The homepage URL https://qubrics.com/docs is not reachable (HTTP status code 522)`. Direct endpoint readback also returned 522. Ops confirmed this is expected until #902/SITE#193; no homepage substitution or audit bypass. Online qualification moves to the cutover steps below. |
| Local install and upgrade | Not measured for this candidate. SDK343's earlier install stopped at Homebrew's one-day dependency cooldown. Public registry readback confirms SDK 3.0.0 publication `2026-11-09T23:16:31.192Z`; do not attempt installation before `2026-11-10T23:16:31.192Z` (11 November 10:16:31 AEDT), or bypass `--min-release-age=1`. |

Local raw receipts: `/Users/rj/Desktop/GIT-REPOS/homebrew-tap/.claude/artifacts/rebrand-qubrics-homebrew14/`: `alias-before.json`, `registry-cli-2.0.0.json`, `sdk-publication-time.json`, `audit-qubrics.log`, `audit-offline.log`, `style.log`, `docs-headers.txt`. SDK343's prior install diagnosis: `/Users/rj/Desktop/GIT-REPOS/sendmux-sdk/.claude/artifacts/rebrand-qubrics-sdk343/homebrew16-result-20261110.md`.

## Cutover verification for #901

Run only after `https://qubrics.com/docs` is live and after 11 November 2026 10:16:31 AEDT. Formula rename publication needs a separate exact-version GO. These are unexecuted steps, not a rehearsal receipt. Do not close #14, #901 or #902 from source preparation alone.

1. Check the public homepage: `curl --fail --location --silent --show-error --output /dev/null --write-out '%{http_code}\n' https://qubrics.com/docs`. Expected: exit 0, HTTP 200. Rollback: none, read-only. A 522 before cutover is expected; after activation, stop and route it to the origin owner.
2. Record the existing installation before any change: `brew list --versions sendmux qubrics`. Expected on the upgrade machine: an existing `sendmux` installation, with its actual version preserved in the receipt. Rollback: none, read-only. Do not replace this with a fresh install and call it an upgrade.
3. With exact-version GO and current-head CI green, merge the rename PR into `qubrics/homebrew-tap` main. Expected: main contains the rename mapping, old-name alias and unchanged Qubrics 2.0.0 formula. Rollback: revert the rename commit to the base above through a reviewed rollback PR. Merge itself publishes to users; never treat it as preparation-only.
4. Refresh the consumer tap: `brew update`. Expected: `qubrics/tap` includes the approved merge. Rollback: restore the approved baseline formula sources through the rollback PR, then refresh again.
5. Trust the canonical replacement: `brew trust --formula qubrics/tap/qubrics`. Expected: only that formula is trusted. Homebrew requires canonical-name trust when an alias resolves to a new target. Rollback: source rollback in step 3 does not revoke trust or downgrade an installed CLI.
6. Run the deferred online gate: `brew audit --strict --new --online qubrics/tap/qubrics`. Expected: exit 0, including reachable canonical homepage. Rollback: none, read-only; a failure stops acceptance and goes to its origin owner without weakening the audit.
7. Upgrade the existing installation: `brew upgrade sendmux`. Expected: exit 0, Homebrew migrates the old formula name and installs Qubrics 2.0.0. Rollback: published source rollback does not automatically undo a completed consumer migration; any manual downgrade is a separately approved action.
8. Read installed identity: `brew list --versions qubrics`. Expected: `qubrics 2.0.0`. Rollback: none, read-only.
9. Read the primary command: `qubrics --version`. Expected: version 2.0.0, matching the public npm package. Rollback: none, read-only.
10. Read compatibility output: `sendmux --version`. Expected: one `sendmux is deprecated. Use qubrics instead.` line and version 2.0.0, exit 0. Rollback: none, read-only.
11. Run the installed formula test: `brew test qubrics/tap/qubrics`. Expected: exit 0. Rollback: none, verification only.
12. Dispatch the existing install workflow on a fresh runner: `gh workflow run tests.yml --repo qubrics/homebrew-tap --ref main`. Expected: the workflow starts from the approved published main commit and performs `brew install --build-from-source qubrics/tap/qubrics`, the formula test and both version readbacks without a pre-existing CLI. Rollback: none, disposable verification; retain the run URL and exact source commit.
13. Find that run: `gh run list --repo qubrics/homebrew-tap --workflow tests.yml --branch main --event workflow_dispatch --limit 1 --json databaseId,headSha,url,status,conclusion`. Expected: the newly dispatched run and the approved main SHA. Then run `gh run watch RUN_ID --repo qubrics/homebrew-tap --exit-status`, replacing `RUN_ID` with that measured databaseId. Expected: exit 0; preserve install and version output. Rollback: none, read-only. Never substitute a successful older run.
14. Read old-name metadata: `brew info --json=v2 qubrics/tap/sendmux`. Expected: canonical name `qubrics`, stable version 2.0.0, alias and oldname `sendmux`. Rollback: none, read-only.

Copy the immutable PR/merge/run URLs and measured outputs into the #901 cutover record and #14 before checking any acceptance box. Tap CI's acceptance criterion does not literally require an online audit before #902; Ops explicitly moved that check to this activation sequence.

## Exact publication and rollback boundary

Proposed publication: replace the separate `sendmux` formula 1.7.1 with an alias of existing `qubrics` formula 2.0.0; do not change or republish the npm package, tarball or SHA256. The local existing-consumer journey starts at installed Sendmux 1.3.1 and targets Qubrics 2.0.0.

Merge publishes this rename to every consumer pulling main. Keep the PR unmerged until Ops approves this exact transition. Rollback is a normal revert restoring base `c9ebc138487f85c590a63edd570a803d82c8968b`: separate Sendmux 1.7.1 and Qubrics 2.0.0 formulae, previous workflow and README. It does not automatically downgrade users already migrated to 2.0.0 or undo commands they ran. No consumer downgrade is claimed or authorised here.

Parked: existing unrelated PR12 (`homebrew/sendmux-v1.7.2`) is untouched. It is not approved for merge by this task.
