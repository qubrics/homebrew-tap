# Homebrew rename preparation (#14)

Status: prepared, not published. No acceptance box is closed by this receipt.

## Candidate and compatibility

- Issue: https://github.com/qubrics/homebrew-tap/issues/14; parent https://github.com/qubrics/qubrics/issues/894, spec A10/A12/A14.
- Base: `c9ebc138487f85c590a63edd570a803d82c8968b`, already live through [PR16](https://github.com/qubrics/homebrew-tap/pull/16). Its [main CI](https://github.com/qubrics/homebrew-tap/actions/runs/42766738138) passed but tested the legacy formula, not the Qubrics formula.
- The unchanged canonical formula installs public `@qubrics/cli@2.0.0` from `https://registry.npmjs.org/@qubrics/cli/-/cli-2.0.0.tgz`. Independent public download on 10 November produced SHA256 `2431314e4e3d4e485b5935a6b74921c09f005e82ebb4bab519d77c6d8911a799`, matching the formula. Public package metadata declares both `qubrics` and `sendmux` launchers and exact dependency `@qubrics/sdk@3.0.0`.
- `formula_renames.json` maps `sendmux` to `qubrics`, retaining the old name as a deprecated pointer. Remove the separate old formula so Homebrew migrates existing installs rather than installing conflicting packages. Homebrew rejects a name appearing as both an explicit alias and a rename; retain the rename mapping alone. Canonical source: [rename guidance](https://github.com/Homebrew/brew/blob/main/docs/Rename-A-Formula.md).
- Deprecation applies to the old name. README points to `qubrics`, and the CLI retains its own old-command warning for one major. Applying `deprecate!` to the shared formula would also deprecate the replacement.
- README and CI use `qubrics/tap/qubrics`. CI retains installation and formula tests, adds explicit version readback and permits a manual fresh-runner readback at cutover.

## Measured preparation

Measured 10 November 2026, before cutover:

| Check | Result |
| --- | --- |
| Existing old-name metadata | `brew info --json=v2 qubrics/tap/sendmux` resolves separate `sendmux` 1.7.1, no aliases or oldnames, not deprecated. Compatibility migration is not live yet. |
| Local installed baseline | `brew list --versions node node@24 sendmux qubrics`: existing `sendmux 1.3.1`; no `qubrics` installed. |
| Whitespace, workflow YAML, JSON syntax, alias target | Passed with `git diff --check`, Ruby YAML parsing, `jq empty`, `test -f` and `readlink`. |
| Candidate tap audit | Initial [CI42801527103](https://github.com/qubrics/homebrew-tap/actions/runs/42801527103) rejected duplicate metadata: `The following should either be an alias or a rename, not both: sendmux`. Removed the redundant `Aliases/sendmux` symlink at the metadata origin, keeping the rename mapping and audit unchanged. Final candidate audit and old-name resolution are recorded after this correction. |
| Offline strict audit | `HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict qubrics/tap/qubrics` exited 0 against the unchanged published 2.0.0 formula. |
| Formula style | `HOMEBREW_NO_AUTO_UPDATE=1 brew style Formula/qubrics.rb` exited 0: `1 file inspected, no offenses detected`. Homebrew emitted a vendor `rubocop-md` obsolete-option warning, not a formula offence. |
| Online audit | Exited 1: `The homepage URL https://qubrics.com/docs is not reachable (HTTP status code 522)`. Direct endpoint readback also returned 522. Ops confirmed this is expected until #902/SITE#193; no homepage substitution or audit bypass. Online qualification moves to the cutover steps below. |
| Local branch install | Attempt from candidate `c1268f4` exited 1 before npm: `qubrics was installed from the sendmux/tap tap but you are trying to install it from the qubrics/tap tap.` Existing receipt source is `sendmux/tap`; current canonical tap is `qubrics/tap`. The install and installed `sendmux 1.3.1` remain intact; the local tap checkout was restored to main `c9ebc138`. |
| Existing-install migration | Homebrew's documented `brew migrate --force` treats renamed packages from different taps as the same source and updates the installed receipt through the vendor migrator. README and cutover steps include that explicit one-time migration for former `sendmux/tap` installs. No uninstall, receipt edit, install `--force`, or trust bypass. Actual migration/upgrade remains unexecuted until the dependency cooldown expires. Canonical [migrate documentation](https://github.com/Homebrew/brew/blob/main/manpages/brew.1.md#migrate-options-installed_formula-installed_cask-). |
| Migration command selection | `HOMEBREW_NO_AUTO_UPDATE=1 brew migrate --dry-run --force qubrics/tap/qubrics` against candidate `c1268f4` exited 0 and printed `Would migrate formula sendmux to qubrics`. Dry-run validates command selection only; it does not claim a completed migration or upgrade. |
| Dependency cooldown | SDK343's earlier install stopped at Homebrew's one-day dependency cooldown. Public registry readback confirms SDK 3.0.0 publication `2026-11-09T23:16:31.192Z`; installation remains ineligible before `2026-11-10T23:16:31.192Z` (11 November 10:16:31 AEDT). No bypass of `--min-release-age=1`. |

Local raw receipts: `/Users/rj/Desktop/GIT-REPOS/homebrew-tap/.claude/artifacts/rebrand-qubrics-homebrew14/`: `alias-before.json`, `registry-cli-2.0.0.json`, `sdk-publication-time.json`, `audit-qubrics.log`, `audit-offline.log`, `style.log`, `docs-headers.txt`, `branch-install.log`. Source trace: `/opt/homebrew/Library/Homebrew/install/check.rb:54` rejects the old tap receipt; `migrator.rb:163` checks tap identity and its `fix_tabs` method owns receipt updates. SDK343's prior install diagnosis: `/Users/rj/Desktop/GIT-REPOS/sendmux-sdk/.claude/artifacts/rebrand-qubrics-sdk343/homebrew16-result-20261110.md`.

## Cutover verification for #901

Run only after `https://qubrics.com/docs` is live and after 11 November 2026 10:16:31 AEDT. Formula rename publication needs a separate exact-version GO. These are unexecuted steps, not a rehearsal receipt. Do not close #14, #901 or #902 from source preparation alone.

1. Check the public homepage: `curl --fail --location --silent --show-error --output /dev/null --write-out '%{http_code}\n' https://qubrics.com/docs`. Expected: exit 0, HTTP 200. Rollback: none, read-only. A 522 before cutover is expected; after activation, stop and route it to the origin owner.
2. Record the existing installation before any change: `brew list --versions sendmux qubrics`. Expected on the upgrade machine: an existing `sendmux` installation, with its actual version preserved in the receipt. Rollback: none, read-only. Do not replace this with a fresh install and call it an upgrade.
3. With exact-version GO and current-head CI green, merge the rename PR into `qubrics/homebrew-tap` main. Expected: main contains the rename mapping retaining the old name and unchanged Qubrics 2.0.0 formula. Rollback: revert the rename commit to the base above through a reviewed rollback PR. Merge itself publishes to users; never treat it as preparation-only.
4. Refresh the consumer tap: `brew update`. Expected: `qubrics/tap` includes the approved merge. Rollback: restore the approved baseline formula sources through the rollback PR, then refresh again.
5. Trust the canonical replacement: `brew trust --formula qubrics/tap/qubrics`. Expected: only that formula is trusted. Homebrew requires canonical-name trust when an alias resolves to a new target. Rollback: source rollback in step 3 does not revoke trust or downgrade an installed CLI.
   If the recorded existing installation came from `sendmux/tap`, first run `brew migrate --force qubrics/tap/qubrics`. Expected: Homebrew migrates the installed old-name keg and receipt to `qubrics/tap` using its documented cross-tap migration command. Keep the migration and upgrade together after the cooldown. Rollback: restoring published formula sources does not automatically reverse consumer migration; any downgrade is separately approved.
6. Run the deferred online gate: `brew audit --strict --new --online qubrics/tap/qubrics`. Expected: exit 0, including reachable canonical homepage. Rollback: none, read-only; a failure stops acceptance and goes to its origin owner without weakening the audit.
7. Upgrade the existing installation: `brew upgrade sendmux`. Expected: exit 0, Homebrew migrates the old formula name and installs Qubrics 2.0.0. Rollback: published source rollback does not automatically undo a completed consumer migration; any manual downgrade is a separately approved action.
8. Read installed identity: `brew list --versions qubrics`. Expected: `qubrics 2.0.0`. Rollback: none, read-only.
9. Read the primary command: `qubrics --version`. Expected: version 2.0.0, matching the public npm package. Rollback: none, read-only.
10. Read compatibility output: `sendmux --version`. Expected: one `sendmux is deprecated. Use qubrics instead.` line and version 2.0.0, exit 0. Rollback: none, read-only.
11. Run the installed formula test: `brew test qubrics/tap/qubrics`. Expected: exit 0. Rollback: none, verification only.
12. Dispatch the existing install workflow on a fresh runner: `gh workflow run tests.yml --repo qubrics/homebrew-tap --ref main`. Expected: the workflow starts from the approved published main commit and performs `brew install --build-from-source qubrics/tap/qubrics`, the formula test and both version readbacks without a pre-existing CLI. Rollback: none, disposable verification; retain the run URL and exact source commit.
13. Find that run: `gh run list --repo qubrics/homebrew-tap --workflow tests.yml --branch main --event workflow_dispatch --limit 1 --json databaseId,headSha,url,status,conclusion`. Expected: the newly dispatched run and the approved main SHA. Then run `gh run watch RUN_ID --repo qubrics/homebrew-tap --exit-status`, replacing `RUN_ID` with that measured databaseId. Expected: exit 0; preserve install and version output. Rollback: none, read-only. Never substitute a successful older run.
14. Read old-name metadata: `brew info --json=v2 qubrics/tap/sendmux`. Expected: canonical name `qubrics`, stable version 2.0.0 and oldname `sendmux`. Rollback: none, read-only.

Copy the immutable PR/merge/run URLs and measured outputs into the #901 cutover record and #14 before checking any acceptance box. Tap CI's acceptance criterion does not literally require an online audit before #902; Ops explicitly moved that check to this activation sequence.

## Exact publication and rollback boundary

Proposed publication: replace the separate `sendmux` formula 1.7.1 with an alias of existing `qubrics` formula 2.0.0; do not change or republish the npm package, tarball or SHA256. The local existing-consumer journey starts at installed Sendmux 1.3.1 and targets Qubrics 2.0.0.

Merge publishes this rename to every consumer pulling main. Keep the PR unmerged until Ops approves this exact transition. Rollback is a normal revert restoring base `c9ebc138487f85c590a63edd570a803d82c8968b`: separate Sendmux 1.7.1 and Qubrics 2.0.0 formulae, previous workflow and README. It does not automatically downgrade users already migrated to 2.0.0 or undo commands they ran. No consumer downgrade is claimed or authorised here.

Parked: existing unrelated PR12 (`homebrew/sendmux-v1.7.2`) is untouched. It is not approved for merge by this task.
