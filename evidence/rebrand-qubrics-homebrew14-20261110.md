# Homebrew rename preparation (#14)

Status: all four #14 acceptance criteria measured on the live tap, 17 November 2026. PR17 published under operator 1B/7A; PR18 repaired CI at its origin. Earlier sections retain preparation history; final results appear below.

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
| Whitespace, workflow YAML and JSON syntax | Passed with `git diff --check`, Ruby YAML parsing and `jq empty`. |
| Candidate tap audit | Initial [CI42801527103](https://github.com/qubrics/homebrew-tap/actions/runs/42801527103) rejected duplicate metadata: `The following should either be an alias or a rename, not both: sendmux`. Removed redundant `Aliases/sendmux` at the metadata origin, keeping the rename mapping and audit unchanged. Local `brew audit --strict qubrics/tap/qubrics` against corrected candidate `8940d81` exited 0; source `/opt/homebrew/Library/Homebrew/tap_auditor.rb:109` forbids the duplicate. |
| Corrected old-name resolution | `brew info --json=v2 qubrics/tap/sendmux` against candidate `8940d81` exited 0: `name=qubrics`, `full_name=qubrics/tap/qubrics`, `oldnames=[sendmux]`, stable version `2.0.0`. Rename mapping alone retains old-name lookup. No installed package or receipt was changed; tap restored to published main afterwards. |
| Offline strict audit | `HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict qubrics/tap/qubrics` exited 0 against the unchanged published 2.0.0 formula. |
| Formula style | `HOMEBREW_NO_AUTO_UPDATE=1 brew style Formula/qubrics.rb` exited 0: `1 file inspected, no offenses detected`. Homebrew emitted a vendor `rubocop-md` obsolete-option warning, not a formula offence. |
| Online audit | Exited 1: `The homepage URL https://qubrics.com/docs is not reachable (HTTP status code 522)`. Direct endpoint readback also returned 522. Ops confirmed this is expected until #902/SITE#193; no homepage substitution or audit bypass. Online qualification moves to the cutover steps below. |
| Local branch install | Attempt from candidate `c1268f4` exited 1 before npm: `qubrics was installed from the sendmux/tap tap but you are trying to install it from the qubrics/tap tap.` Existing receipt source is `sendmux/tap`; current canonical tap is `qubrics/tap`. The install and installed `sendmux 1.3.1` remain intact; the local tap checkout was restored to main `c9ebc138`. |
| Existing-install migration | Homebrew's documented `brew migrate --force` treats renamed packages from different taps as the same source and updates the installed receipt through the vendor migrator. README and cutover steps include that explicit one-time migration for former `sendmux/tap` installs. No uninstall, receipt edit, install `--force`, or trust bypass. Actual migration/upgrade remains unexecuted until the dependency cooldown expires. Canonical [migrate documentation](https://github.com/Homebrew/brew/blob/main/manpages/brew.1.md#migrate-options-installed_formula-installed_cask-). |
| Migration command selection | `HOMEBREW_NO_AUTO_UPDATE=1 brew migrate --dry-run --force qubrics/tap/qubrics` against candidate `c1268f4` exited 0 and printed `Would migrate formula sendmux to qubrics`. Dry-run validates command selection only; it does not claim a completed migration or upgrade. |
| Dependency cooldown | SDK343's earlier install stopped at Homebrew's one-day dependency cooldown. Public registry readback confirms SDK 3.0.0 publication `2026-11-09T23:16:31.192Z`; installation remains ineligible before `2026-11-10T23:16:31.192Z` (11 November 10:16:31 AEDT). No bypass of `--min-release-age=1`. |

Local raw receipts: `/Users/rj/Desktop/GIT-REPOS/homebrew-tap/.claude/artifacts/rebrand-qubrics-homebrew14/`: `alias-before.json`, `alias-after.json`, `registry-cli-2.0.0.json`, `sdk-publication-time.json`, `audit-qubrics.log`, `audit-offline.log`, `audit-candidate.log`, `style.log`, `docs-headers.txt`, `branch-install.log`, `migration-dry-run.log`, `tap-pr17-failed.log`. Source trace: `/opt/homebrew/Library/Homebrew/install/check.rb:54` rejects the old tap receipt; `migrator.rb:163` checks tap identity and its `fix_tabs` method owns receipt updates. SDK343's prior install diagnosis: `/Users/rj/Desktop/GIT-REPOS/sendmux-sdk/.claude/artifacts/rebrand-qubrics-sdk343/homebrew16-result-20261110.md`.

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

## Read-only activation checks — 16 November 2026

Measured 22:48–22:52 AEDT, after Ops reported #901 P6 live. PR17 remains OPEN/CLEAN at approved `cfb50dcf7dc36c4466e84701f4b6baf33f1b92cb`; base remains `c9ebc138487f85c590a63edd570a803d82c8968b`. This evidence addition uses the separate task branch `agent/rebrand-qubrics-homebrew14-evidence` so the approved PR head stays unchanged. No tap publication, package installation, receipt migration or upgrade was performed.

- Step 1: `curl --fail --location --silent --show-error --max-time 30 --output /dev/null --write-out '%{http_code}\n' https://qubrics.com/docs` exited 0 and returned `200`. The same apex check returned `200`.
- Step 6: `HOMEBREW_NO_AUTO_UPDATE=1 brew audit --strict --new --online qubrics/tap/qubrics` exited 0. Only the existing vendor `rubocop-md` obsolete-option warning was emitted; no formula offence or audit exception was suppressed.
- Audit input: PR17's `Formula/qubrics.rb` is byte-identical to the installed canonical tap's file (`cmp -s` exited 0). The formula is unchanged by PR17. Named audit therefore checks the approved formula bytes; PR17's rename metadata was separately qualified by its green current-head CI. Installed tap sources remain at the published base; no checkout was changed for this check.
- Initial invocation correction: Homebrew rejected the absolute file argument before auditing. Its `/opt/homebrew/Library/Homebrew/dev-cmd/audit.rb:168` explicitly disables `brew audit [path ...]` and requires names. The supported named command above fixed the invocation at its origin; all requested audit flags were retained.

Raw receipts under `/Users/rj/Desktop/GIT-REPOS/homebrew-tap/.claude/artifacts/rebrand-qubrics-homebrew14/`: `gate-20261116-docs-status.txt`, `gate-20261116-docs-headers.txt`, `gate-20261116-homepage-status.txt`, `gate-20261116-homepage-headers.txt`, `audit-online-20261116.log` and `audit-path-rejected-20261116.log`.

The 11 November 7A decision at Ops `decisions.md:403` says `7A homebrew14 conditional GO (tap PR17 after cooldown 10:16, conditions per ask)`. The exact publication packet's conditions evaluate as follows:

| Verbatim condition | Measured result |
| --- | --- |
| `at candidate cfb50dcf7dc36c4466e84701f4b6baf33f1b92cb` | PASS: local HEAD and live PR17 head both match; no merge yet. |
| `after 11 November 2026 10:16:31 AEDT` | PASS: host date is 16 November 2026, 22:48 AEDT. |
| `after https://qubrics.com/docs is live` | PASS: docs and apex HTTP 200, both curl commands exited 0. |
| `current-head required CI passes` / `current-head CI green` | PASS: live PR17 check `test` is SUCCESS for the approved head, [run42802197904 attempt 2](https://github.com/qubrics/homebrew-tap/actions/runs/42802197904/attempts/2). CodeRabbit remains SKIPPED under its existing policy; it is not reported as a passed check. |
| `exact-version publication GO` | Standing conditional 7A applies to the exact transition below; it does not remove the separate window condition. |
| `and the separately approved cutover verification window opens` | ASK: this condition names cutover. Per Ops' 16 November instruction, do not infer merge authority from the website's HTTP 200; hold and quote the condition. |

The packet also states `Online audit, published fresh install and existing-install upgrade/version proof remain #901 cutover steps before D21 closure.` Ops explicitly authorised the read-only audit now. Published fresh install and existing-install migration/upgrade remain unexecuted; no acceptance box is closed from these checks alone.

Ops disposition at 22:57 AEDT: keep PR17 held. The cutover verification window is 17 November 17:00–20:15 AEDT and is still awaiting approval. Once it is approved and open, recheck PR17 head and CI, then merge only the approved `cfb50dcf7dc36c4466e84701f4b6baf33f1b92cb` under standing 7A. No further Ops ping until the window.

Exact publication remains separate Sendmux 1.7.1 → old-name pointer to Qubrics 2.0.0, using unchanged `@qubrics/cli@2.0.0` and SHA256 above. Rollback remains a normal revert restoring base `c9ebc138487f85c590a63edd570a803d82c8968b`; already migrated consumers are not automatically downgraded. No merge or publication from this evidence branch.

## Approved publication and live upgrade — 17 November 2026

Operator 1B opened the joint cutover window immediately at 10:41 AEDT instead of 17:00 (Ops `decisions.md:540`). Ops explicitly directed this session to merge PR17 under 7A, confirm the tap run and read the installed formula. Every publication condition was checked before merging:

| 7A condition | Live result |
| --- | --- |
| Exact candidate | PR17 OPEN/CLEAN at `cfb50dcf7dc36c4466e84701f4b6baf33f1b92cb`, base `c9ebc138487f85c590a63edd570a803d82c8968b`; clean local candidate. |
| Current-head CI green | `test` SUCCESS on [42802197904 attempt 2](https://github.com/qubrics/homebrew-tap/actions/runs/42802197904/attempts/2). No review threads or legacy status contexts; CodeRabbit SKIPPED by existing policy. |
| After 11 November 10:16:31 AEDT | Host clock 17 November 10:43 AEDT. |
| Docs live | Both `curl --fail --location` checks exited 0: `200 https://qubrics.com/docs` and `200 https://qubrics.com/`. |
| Exact-version GO | Standing 7A for the unchanged CLI 2.0.0 tarball and rename, explicitly reconfirmed by Ops in the open window. |
| Separately approved cutover verification window opens | Operator 1B explicitly opened it now; prior HOLD superseded. |

`gh pr merge 17 --repo qubrics/homebrew-tap --merge --match-head-commit cfb50dcf7dc36c4466e84701f4b6baf33f1b92cb` exited 0. Independent API readback: [PR17](https://github.com/qubrics/homebrew-tap/pull/17) MERGED at `2026-11-16T23:44:23Z` (17 November 10:44:23 AEDT), [merge 5b46a0253071d0e864978cda91609b5584db2046](https://github.com/qubrics/homebrew-tap/commit/5b46a0253071d0e864978cda91609b5584db2046). This is the live formula publication; no npm publication occurred.

Consumer commands below ran against that published tap, with `HOMEBREW_NO_AUTO_UPDATE=1` after the explicit refresh. No cooldown, audit or trust check was disabled.

| Command/readback | Measured result |
| --- | --- |
| Before changes: `brew list --versions sendmux qubrics` | `sendmux 1.3.1`; no Qubrics installed (exit 1 because one requested formula was absent). Original receipt `source.tap=sendmux/tap`, stable `1.3.1`. |
| `brew update` | Exit 0; consumer tap HEAD became `5b46a0253071d0e864978cda91609b5584db2046`. Homebrew itself updated 7.0.13 → 7.0.14. It reported the known old-name receipt tap mismatch during automatic migration. |
| `brew trust --formula qubrics/tap/qubrics` | Exit 0, already trusted. |
| `brew migrate --force qubrics/tap/qubrics` | Exit 0: migrated `sendmux` to `qubrics`, unlinked old name, moved existing 1.3.1 keg, relinked. No uninstall or hand-edited receipt. |
| `brew audit --strict --new --online qubrics/tap/qubrics` | Exit 0 against published tap and Homebrew 7.0.14. |
| `brew upgrade sendmux` | Exit 0: `qubrics/tap/qubrics 1.3.1 -> 2.0.0`, one requested package upgraded; npm installation and tarball verification succeeded. Homebrew installed/upgraded required Node dependencies. |
| `brew list --versions qubrics` | Exit 0: `qubrics 2.0.0`. |
| `qubrics --version` | Exit 0: `@qubrics/cli/2.0.0 darwin-arm64 node-v26.13.1`. |
| `sendmux --version` | Exit 0: exactly one `sendmux is deprecated. Use qubrics instead.` line, then `@qubrics/cli/2.0.0 darwin-arm64 node-v26.13.1`. |
| `brew test qubrics/tap/qubrics` | Exit 0; ran installed version and help tests. |
| Installed receipt | `source.tap=qubrics/tap`, `tap_git_head=5b46a0253071d0e864978cda91609b5584db2046`, stable `2.0.0`. |
| `brew info --json=v2 qubrics/tap/sendmux` | Exit 0: `name=qubrics`, `full_name=qubrics/tap/qubrics`, `oldnames=[sendmux]`, stable/installed `2.0.0`. Canonical replacement is not deprecated; legacy command emits the warning. |
| Public npm readback | `@qubrics/cli@2.0.0`, both binaries, unchanged `https://registry.npmjs.org/@qubrics/cli/-/cli-2.0.0.tgz`. |

The refresh messages all came from the already-diagnosed legacy receipt source. `/opt/homebrew/Library/Homebrew/migrator.rb:163` rejects a different tap unless its documented migration command is used. The vendor migrator moved the actual existing keg; the subsequent upgrade wrote a canonical `qubrics/tap` receipt. Successful upgrade and old-name lookup confirm the cause is removed. No retry, relief or manual receipt edit was used as a fix.

Fresh-install/main CI: [43981862392](https://github.com/qubrics/homebrew-tap/actions/runs/43981862392), automatically triggered by the publication push on exact merge `5b46a025`, **FAILED** after installing CLI 2.0.0 successfully. Audit/style/install passed; formula test stopped before executing its assertions; both-version readback was skipped. No rerun was issued. No full CI or final acceptance is claimed from this run.

Candidate reopened: main CI is red, blocking the explicit tap-CI acceptance clause. Exact failing line (`publish-ci-20261117.log:366`): `qubrics/tap/qubrics has outdated test dependencies: simdutf ada-url libffi llhttp merve node`. Lines 322–349 show those same six dependencies freshly installed at versions selected by the newly cloned core Git tap. This rules out a missing dependency or an installation that silently skipped an old dependency.

Confirmed workflow defect: `.github/workflows/tests.yml` forced `HOMEBREW_NO_INSTALL_FROM_API=1` for installation alone, then ran the test without it. Homebrew's `docs/Manpage.md:5066` says that override selects local Git metadata for **core/cask**, not third-party taps. `dependency.rb:115` requires the metadata source's latest installed version; `dev-cmd/test.rb:77` rejects mismatches as outdated before running the formula test. These traces support metadata-version skew between the runner's two sources; the failed runner's API version inventory was not captured. Local read-only inventories from both modes agree after `brew update`, consistent with the passing local test. Green changed-workflow CI must confirm the repair; installation success rules out the old release-age failure, and the homepage audit passed.

Minimal origin fix: remove only the install command's API override. Install and test now both use Homebrew's default API metadata for core dependencies; the fully qualified `qubrics/tap/qubrics` still reads the checked-out third-party tap. Keep the strict audit, formula test, source install and both version assertions unchanged. No dependency pin, forced upgrade list, test suppression or retry is the fix. Existing CI is the regression test: the original run is red; the changed workflow must pass on a new commit before acceptance.

Review: both independent Standards and Spec checks found no functional defect or scope creep in the repair. Both flagged the same diagnostic wording; the paragraph above now distinguishes the measured source-mode mismatch from the unrecorded runner API inventory. No new harness or test was added; the existing CI tests the actual failure path.

Repair confirmed by [CI43983445676](https://github.com/qubrics/homebrew-tap/actions/runs/43983445676) on exact commit `fbb80c5baaac82d93945790136cd592dc15b0a07`: every step SUCCESS, watch exit 0. Fresh install built CLI 2.0.0; installed formula version/help assertions passed. Both commands exited 0 with `@qubrics/cli/2.0.0 darwin-arm64 node-v26.13.0`; old command emitted exactly one deprecation line. This runner used API-selected Node 26.13.0, while the failed Git-mode run installed Node 26.13.1_2. The difference now has a measured version readback, confirming source skew rather than an absent dependency. Changing the metadata source at installation removed the original test-preflight failure without suppressing it.

Task source tarball cache and download were deleted after the local build; both paths verified absent. Shared package-manager caches are vendor-owned across formula builds (`package_manager_cache.rb:7`) and were not purged. No task server, container or background build was created. Final workflow merge/main readback remains outstanding; do not close #14 from a green branch alone.

Raw receipts retained in the MAIN artifact directory above for the open #901/#902 cutover: `brew-update-20261117.log`, `brew-migrate-20261117.log`, `audit-online-20261117.log`, `brew-upgrade-20261117.log`, `installed-version-20261117.txt`, `qubrics-version-20261117.txt`, `sendmux-version-20261117.txt`, `old-name-info-20261117.json`, `brew-test-20261117.log`, `publish-watch-20261117.log`, `publish-ci-20261117.log`, `publish-failed-20261117.log`.

Rollback remains a normal revert of merge `5b46a0253071d0e864978cda91609b5584db2046` (`git revert -m 1 5b46a0253071d0e864978cda91609b5584db2046`) through a reviewed rollback PR, restoring published source to `c9ebc138487f85c590a63edd570a803d82c8968b`. It does not downgrade already migrated consumers; no downgrade is authorised.

## Final live acceptance

[PR18](https://github.com/qubrics/homebrew-tap/pull/18) merged exact reviewed/green head `6268d0d545b5fd1509f8d28db21c2fc97a7d0af1` as [86a3d9fcbe759df3c51fcb535a5ac22c05fac252](https://github.com/qubrics/homebrew-tap/commit/86a3d9fcbe759df3c51fcb535a5ac22c05fac252) at `2026-11-17T00:02:41Z` (11:02:41 AEDT). Three-minute final review sweep at 11:02 AEDT: no outstanding comments, reviews, threads or status contexts; existing CodeRabbit policy SKIPPED, not reported as passed. Independent review: one shared evidence-wording finding fixed, no functional findings. This in-scope repair changed only workflow/evidence, satisfying Ops' earlier non-publishing merge condition. `git diff --exit-code 5b46a025 HEAD -- Formula formula_renames.json README.md` exited 0 before merge: no additional formula, name or version publication.

[Final main CI43984371201](https://github.com/qubrics/homebrew-tap/actions/runs/43984371201) ran on exact published `86a3d9fcbe759df3c51fcb535a5ac22c05fac252`: **SUCCESS**, all steps succeeded, `gh run watch --exit-status` exited 0. Fresh runner installed `qubrics/tap/qubrics` 2.0.0, passed installed version/help tests, and printed both CLI 2.0.0 readbacks with exactly one legacy deprecation line. No required step skipped. Raw final log: MAIN `.claude/artifacts/rebrand-qubrics-homebrew14/main-final-ci-20261117.log`.

| #14 acceptance | Measured live proof |
| --- | --- |
| Qubrics installs; version matches published CLI | Final main fresh install/test/readback SUCCESS; `@qubrics/cli/2.0.0 darwin-arm64 node-v26.13.0`. Public registry version is 2.0.0. |
| Sendmux deprecated pointer; existing upgrade succeeds | Actual installed 1.3.1 keg migrated by vendor command, then `brew upgrade sendmux` exited 0 to `qubrics 2.0.0`. Local primary/legacy readbacks both 2.0.0; one legacy deprecation line. Old-name info resolves `qubrics/tap/qubrics`, `oldnames=[sendmux]`. New receipt names canonical tap and approved publication commit. |
| Tap CI green on canonical name | Final published-main CI43984371201 passed canonical tap/trust/audit/style/install/test/version steps. Original failed signal is clean after removing its metadata-source cause; no rerun or suppressed assertion. |
| README canonical install line | Independent GitHub contents API readback at published `86a3d9fc` returns README line 10: `brew install qubrics/tap/qubrics`. Rename map API readback returns `{"sendmux":"qubrics"}`. |

✅ Complete — formula live at 2.0.0; 4/4 acceptance criteria proven. PR17 and the CI origin repair are merged. CLI/package version, tarball and SHA256 remain the approved values. No npm publish was performed by this session.

Correctness: Homebrew rename map owns old-name resolution; vendor migration/upgrade replaces the actual old install and writes canonical receipt identity. Existing formula test and CI walked real install/upgrade paths. Tests: no new harness, no assertion change, no removed test. Journeys: fresh install ✓, existing upgrade ✓, old-name lookup ✓, legacy warning ✓, strict online audit ✓.

Rollback after the CI-only follow-up: revert merge `86a3d9fcbe759df3c51fcb535a5ac22c05fac252` first, then rename merge `5b46a0253071d0e864978cda91609b5584db2046`, each with `git revert -m 1` through the reviewed rollback PR. This restores prior source `c9ebc138487f85c590a63edd570a803d82c8968b`. Source rollback does not downgrade migrated users. No manual consumer downgrade is authorised.

Cleanup: task source tarball cache/download already removed and absence verified; no task server/container created; all owned CI watches exited. Sessions, task goal/hold and live ownership were checked before teardown. This final evidence is pushed on the separate evidence branch before removing the clean task tap worktree. #14's closure comment records the subsequent verified teardown; Superset spec workspace and unrelated shared work remain with their live owners. MAIN raw receipts remain cited by open #901/#902.

Parked: existing npm/Homebrew build-from-source warning, outside this rename; no remaining goal blocker. Unrelated PR12 remains untouched.
