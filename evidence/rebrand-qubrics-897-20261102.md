# GitHub live references — Homebrew tap

Part of qubrics/qubrics#897, spec A15. Source-only PR; no merge, publication, deployment or GitHub settings change.

README and CI commands now address `qubrics/tap/sendmux`; local tap setup uses `qubrics/tap`. This updates the GitHub tap owner while preserving the existing formula, CLI/package names, formula version and registry artifact. A14 owns the future formula rename and compatibility alias.

Checks: `git diff --check`, `ruby -c Formula/sendmux.rb` and the live old-owner/repository reference scan passed. Existing macOS CI owns online formula audit, installation and formula execution; those network/install checks were not duplicated locally. No tests or test harnesses were added.

GitHub Tests CI is required on the PR. Independent review is coordinated across the batch; no review-settled claim is made here.

Candidate reopened: macOS CI failed before audit because Homebrew 6 requires explicit trust for a non-official formula. Run 41405072268 reports `Refusing to load formula qubrics/tap/sendmux from untrusted tap qubrics/tap.` Canonical fix per official `https://docs.brew.sh/Tap-Trust`: after tapping the owned local checkout, run `brew trust --formula qubrics/tap/sendmux` before audit. Trust is limited to the exact formula under test; no global bypass or whole-tap trust. CI is the red/green proof; no Mac install performed locally.
