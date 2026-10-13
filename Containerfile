# Toolchain image for dialectic-playground/rb: Ruby (container-first; see tools/dp-run).
#
# Ruby 4.0; build and package tool: Bundler.
# Official base image pinned by multi-architecture index digest, plus make and python3 (for the
# curriculum's black-box runner), and gcc + libc6-dev to build the C extensions of the locked
# development gems (json, prism, racc; the slim image has no compiler). Dependabot (docker)
# refreshes the digest; moving to a new release line is a deliberate change (keep
# `make toolchain` and the native CI in step).
FROM docker.io/library/ruby:4.0-slim-trixie@sha256:ba6a00593739f9cb66de80ad2e395a93a52a13635867ee32918ba0ec083b1ff6

RUN apt-get update \
    && apt-get install -y --no-install-recommends make python3 gcc libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Gems and bundles in the mounted cache (the image's GEM_HOME is read-only for your user).
ENV GEM_HOME=/dp-cache/ruby/gems \
    BUNDLE_PATH=/dp-cache/ruby/bundle \
    PATH=/dp-cache/ruby/gems/bin:$PATH \
    DP_IN_CONTAINER=1
