<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/dialectic-playground/.github/main/assets/rb/dist/logo-dark.svg">
    <img alt="dialectic playground / rb" src="https://raw.githubusercontent.com/dialectic-playground/.github/main/assets/rb/dist/logo.svg" height="96">
  </picture>
</p>

# rb

Ruby implementation of the Dialectic Playground SDLC curriculum.

📖 **Documentation:** <https://dialectic-playground.github.io/docs/reference/languages/rb/>

This repository implements the eleven projects of the
[SDLC curriculum](https://github.com/dialectic-playground/sdlc-curriculum) in Ruby. Each project is
specified to the byte by the curriculum and verified by its black-box tests on Linux, macOS,
and Windows.

**Status:** Implemented projects: 00-hello-world.

## Ruby at a glance

| Aspect | Ruby |
| :-- | :-- |
| File extension | `.rb` |
| CLI classification | Included |
| Image category | First-Class |
| Access to OS primitives | High (via native process automation libraries) |
| Entry-point mechanism | Interpreter bootstraps file and wraps arguments into ARGV array |

## Toolchain

| | |
| :-- | :-- |
| Release line | Ruby 4.0 |
| Build / package tool | Bundler |
| Container image | `ruby:4.0-slim-trixie`, pinned by digest ([`Containerfile`](Containerfile)) |
| Native CI | ruby/setup-ruby (4.0, includes Bundler; on Windows, RubyInstaller with the MSYS2 devkit) |
| Unit tests | minitest (listed in each project's `Gemfile`: it is a bundled gem, not a default gem) |
| Lint / format | RuboCop (`bundle exec rubocop` / `rubocop --autocorrect`) |
| Dependencies | Per project: `Gemfile` and `Gemfile.lock` (exact versions and checksums; Dependabot `bundler`) |

`make toolchain` verifies that the container and native toolchains are on this release line.
The container image adds `gcc` and `libc6-dev` to the slim Ruby image so Bundler can build the
C extensions of the locked development gems (json, prism, racc); natively, ruby/setup-ruby
provides a compiler. Bundler installs the gems outside the project directories
(`BUNDLE_PATH=/dp-cache/ruby/bundle` in the container, the Ruby installation's gem directory
natively); the tools themselves use only the standard library and run without Bundler.
For a native build on Linux, install your distribution's Ruby headers (for example
`ruby-devel` on Fedora) so the gems can compile.

Each tool is an extensionless `#!/usr/bin/env ruby` launcher in its project's `src/bin/`.
`make install` copies `src/bin` and `src/lib` to `$(LIBDIR)/rb/<project>/` and writes a small
`#!/bin/sh` launcher to `$(BINDIR)`. **Windows:** run the tools from Git Bash or MSYS2, which
honor `#!` lines.

## Layout

| Path | Contents |
| :--- | :--- |
| `00-hello-world/` … `10-sys-monitor/` | One workspace per curriculum project: `Makefile` (with `DP_*` hooks), HLD, LLD, RTM, master test plan, and `src/` |
| `sdlc-curriculum/` | The curriculum, as a git submodule pinned to a release tag |
| `Makefile` | `make check` (repository, toolchain, implemented projects), `toolchain`, `projects`, `roundtrip` |
| `Containerfile`, `.devcontainer/` | The toolchain image and the matching dev container |
| `tools/dp-run`, `tools/container.mk` | Shared container tooling (copies of the canonical files in `dialectic-playground/.github`) |
| `.github/workflows/ci.yml` | CI: container and native (Linux, macOS, Windows) `make` targets, shared-tooling check, DCO |

## Development

Container-first: `make` targets and `tools/dp-run <command>` run in the toolchain container
via Podman, then Docker, then the local system. `DP_RUNTIME=podman|docker|local` overrides
the choice.

```sh
git clone --recurse-submodules https://github.com/dialectic-playground/rb.git
cd rb
make check                    # repository, toolchain, and every implemented project
DP_RUNTIME=local make check   # the same with your native toolchain
make -C 00-hello-world help   # a project's configuration and hooks
```

## Implementing a project

1. Complete the project's `hld.md` and `lld.md` before writing code.
2. Write the implementation and its unit tests under the project's `src/`, add the
   repository's Bundler configuration, and fill in `BIN_DIR` and the `DP_*` hooks in
   the project's `Makefile`.
3. Pass `make -C <project> test` (container) and `DP_RUNTIME=local make -C <project> test`.
4. Add the project directory to `IMPLEMENTED` in the root `Makefile`. CI then builds, lints,
   and tests it in the container and natively on all three operating systems.
5. Keep `rtm.md` and `master-test-plan.md` current.

Specifications: [curriculum reference](https://dialectic-playground.github.io/docs/reference/curriculum/). Language setup:
[Set up a language repository](https://dialectic-playground.github.io/docs/how-to/set-up-a-language-repository/).

## Contributing

See the [organization contributing guide](https://github.com/dialectic-playground/.github/blob/main/CONTRIBUTING.md).
Pull requests are squash-merged, titles follow Conventional Commits, and every commit needs a
DCO sign-off.

## License

[MIT](LICENSE)
