# Setup PR #13: Homebrew trust failure

PR [#13](https://github.com/qubrics/homebrew-tap/pull/13), head `813f7b02b00815e0dd45cfcfba57fc1450818ce4`, failed before audit could inspect the formula. [Tests run 41396126584](https://github.com/qubrics/homebrew-tap/actions/runs/41396126584) stopped at `Audit formula` with `Refusing to load formula sendmux/tap/sendmux from untrusted tap sendmux/tap.`

Renaming did not solve it. [Run 41405072268](https://github.com/qubrics/homebrew-tap/actions/runs/41405072268), head `a9a03930503b0756a3b74da0afa46a81de8744c3`, still refused to load `qubrics/tap/sendmux` from untrusted tap `qubrics/tap`.

[Homebrew Tap Trust](https://docs.brew.sh/Tap-Trust) requires explicit trust before loading non-official formula definitions because they can execute Ruby. For automation, Homebrew recommends trusting only the required item.

Merged PR [#15](https://github.com/qubrics/homebrew-tap/pull/15), commit `37b468f017626dc3863a135749d426c12646e572`, fixes `.github/workflows/tests.yml:19` by tapping the current owner and trusting the exact local formula before the unchanged strict online audit, installation and formula tests. [Main Tests run 41413028616](https://github.com/qubrics/homebrew-tap/actions/runs/41413028616) passed those checks.

This branch merges the existing main fix into #13 and adds no trust rule or check exemption. [Issue #14](https://github.com/qubrics/homebrew-tap/issues/14) remains separate. No package, tag or release is published here.

Local validation: `git diff --check` and `ruby -c Formula/sendmux.rb`. Updated branch verification is recorded in [PR #13 checks](https://github.com/qubrics/homebrew-tap/pull/13/checks). Parent session owns normal merge and post-merge main verification.
