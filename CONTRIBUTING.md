# Contributing to nlink-jp

Thank you for your interest in the nlink-jp tools. This guide applies to every
repository in the organization unless the repository says otherwise.

日本語版: [CONTRIBUTING.ja.md](https://github.com/nlink-jp/.github/blob/main/CONTRIBUTING.ja.md)

## Start with an issue

**Please open an issue before writing code.**

- **Bug reports** — include the OS and its version (for example macOS 26.1),
  the tool's version (`--version`, or the version shown in the app), what you
  did, what you expected, and what happened instead.
- **Feature ideas** — describe the problem you want solved, not only the
  change you have in mind. We may solve it differently.

Issues in English or Japanese are both fine.

## How pull requests are handled

Pull requests are welcome **as proposals**, but please know this before you
spend time on one:

**We generally do not merge pull requests from outside the organization as
they are.** When we want a change, we write it ourselves, following the
repository's conventions with tests and documentation, and credit you in the
commit message and the changelog.

This is not about the quality of your work. We do not ship code written outside
the organization (a supply-chain policy that we also apply to our own
dependencies), and every release is built, signed and notarized by the
maintainers.

A pull request is still useful when it is the clearest way to show what you
mean. If you send one:

- **One change per pull request**, linked to its issue. Do not bundle
  unrelated changes.
- **Tests** for new behaviour.
- **Documentation**: update `README.md` and `README.ja.md` together.
- **No AI-agent working files** (`.claude/`, `.kilo/`, `.cursor/`, plan or note
  files). Changes prepared with AI tools are fine; please review them yourself
  first.
- **No CI workflows** (`.github/workflows/`). Releases are built, signed and
  notarized locally by design.
- **No new third-party dependencies.** We use the standard library, the
  platform's first-party SDKs, or a service's REST API directly.

## Credit

When your report or proposal leads to a change, the commit message and the
changelog name you. We follow up on the issue or pull request when it ships.
