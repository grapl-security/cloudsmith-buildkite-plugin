#!/usr/bin/env bash

set -euo pipefail

readonly default_image="docker.cloudsmith.io/grapl/releases/cloudsmith-cli"
readonly default_tag="latest"
# TODO: add a "debug" mode where we spit out the specific image and
# commands being used
readonly image="${BUILDKITE_PLUGIN_CLOUDSMITH_IMAGE:-${default_image}}:${BUILDKITE_PLUGIN_CLOUDSMITH_TAG:-${default_tag}}"

# Wrap up the invocation of a Cloudsmith container image to alleviate the
# need to have a Cloudsmith binary installed on the Buildkite agent machine
# already. Scripts can just source this file and then call `cloudsmith`
# like normal.
# TODO: If used to upload raw files, we would also need to mount the current directory.
cloudsmith() {
    docker run \
        --init \
        --rm \
        --env=CLOUDSMITH_API_KEY \
        -- \
        "${image}" "$@"
}
