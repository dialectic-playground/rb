# 00-hello-world: Standard Terminal Hello World, in Ruby (4.0).
#
# Extends the universal build contract in shared/templates/BASE-MAKEFILE:
#
#   make all | install | uninstall | test | check | lint | format | clean | distclean
#   make test-hidden | grade | help
#
# Toolchain: Ruby 4.0 and Bundler. The tool uses only the standard library: src/lib holds the
# DpHello library, src/bin the extensionless `#!/usr/bin/env ruby` launcher, src/test the
# minitest unit tests. Gemfile and Gemfile.lock pin the development dependencies (minitest,
# RuboCop); Bundler installs them into its configured location (BUNDLE_PATH in the container,
# the Ruby installation's gem directory natively), never into this directory.
#
# Build: nothing to compile. `make all` leaves src/bin/dp-hello executable, so BIN_DIR is
# src/bin. Lint (RuboCop, which also checks the layout) fails on any offense; format applies
# RuboCop's safe autocorrections (rubocop -a).
#
# Install: src/{bin,lib} go to $(LIBDIR)/rb/00-hello-world, and a `#!/bin/sh` launcher that runs
# the installed bin/dp-hello with ruby (absolute path baked in) goes to $(BINDIR)/dp-hello.
# Uninstall removes both.
#
# Container-first: goals run in the toolchain container built from the repository's
# Containerfile (podman, then docker, then local; override with DP_RUNTIME).

PROJECT := 00-hello-world
TOOLS   := dp-hello

# Path to the sdlc-curriculum checkout (the specs, test suites, and runner live there).
CURRICULUM_ROOT ?= ../sdlc-curriculum

RUBY   ?= ruby
BUNDLE ?= bundle

# Directory that contains the built executables after `make all`.
BIN_DIR := src/bin

# Where `make install` puts the payload (see the header).
INSTALL_DIR = $(LIBDIR)/rb/$(PROJECT)

# Gemfile.lock is authoritative: Bundler must not re-resolve or rewrite it.
export BUNDLE_FROZEN := true

# Install the locked development gems unless they are already present.
BUNDLE_INSTALL = $(BUNDLE) check >/dev/null 2>&1 || $(BUNDLE) install --quiet
RUBOCOP = $(BUNDLE) exec rubocop
UNIT_TESTS = $(BUNDLE) exec $(RUBY) -w -e \
	'Dir.glob("src/test/**/*_test.rb").sort.each { |file| require File.expand_path(file) }'

DP_BUILD = chmod +x $(BIN_DIR)/dp-hello

define DP_UNIT_TEST
$(BUNDLE_INSTALL)
$(UNIT_TESTS)
endef

define DP_LINT
$(BUNDLE_INSTALL)
$(RUBOCOP)
endef

define DP_FORMAT
$(BUNDLE_INSTALL)
$(RUBOCOP) --autocorrect --format quiet --fail-level fatal
endef

define DP_INSTALL
rm -rf "$(INSTALL_DIR)"
mkdir -p "$(INSTALL_DIR)" "$(BINDIR)"
cp -R src/bin src/lib "$(INSTALL_DIR)/"
printf '#!/bin/sh\nexec ruby %s "$$@"\n' "'$(INSTALL_DIR)/bin/dp-hello'" \
	> "$(BINDIR)/dp-hello"
chmod +x "$(BINDIR)/dp-hello"
"$(BINDIR)/dp-hello" --version
endef

define DP_UNINSTALL
rm -f "$(BINDIR)/dp-hello"
rm -rf "$(INSTALL_DIR)"
rmdir "$(LIBDIR)/rb" "$(LIBDIR)" 2>/dev/null || true
endef

# Nothing is generated in this directory; remove the usual Ruby scratch directories.
DP_CLEAN = rm -rf coverage tmp

# Bundler's local configuration and a project-local bundle (`bundle config set --local path`).
DP_DISTCLEAN = rm -rf .bundle vendor

include $(CURRICULUM_ROOT)/shared/templates/BASE-MAKEFILE
