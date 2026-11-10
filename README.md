# Qubrics Homebrew tap

Install and upgrade the Qubrics CLI with Homebrew.

## Install

Install the Qubrics CLI:

```sh
brew install qubrics/tap/qubrics
```

Check the installed command:

```sh
qubrics --version
qubrics --help
```

## Upgrade

```sh
brew update
brew upgrade qubrics
```

The `sendmux` formula name is a deprecated alias of `qubrics`. To migrate an existing install:

```sh
brew update
brew trust --formula qubrics/tap/qubrics
```

If the existing install came from the former `sendmux/tap`, migrate its tap identity:

```sh
brew migrate --force qubrics/tap/qubrics
```

Then upgrade:

```sh
brew upgrade sendmux
qubrics --version
```

The CLI also keeps a deprecated `sendmux` command for one major version.

## Formulae

| Formula | Installs | Documentation |
| --- | --- | --- |
| `qubrics` | The `qubrics` CLI | [qubrics.com/docs/cli](https://qubrics.com/docs/cli) |
| `sendmux` | Deprecated alias of `qubrics` | [qubrics.com/docs/cli](https://qubrics.com/docs/cli) |

## Maintainers

Update `Formula/qubrics.rb` from the SDK release workflow after `@qubrics/cli` publishes to npm.

Local verification:

```sh
brew audit --strict qubrics/tap/qubrics
brew style qubrics/tap/qubrics
brew install --build-from-source qubrics/tap/qubrics
brew test qubrics/tap/qubrics
```
