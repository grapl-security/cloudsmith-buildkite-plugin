#!/usr/bin/env bash

set -euo pipefail

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

if [[ -z "${BUILDKITE_PLUGIN_CLOUDSMITH_IMAGE+x}" ]]; then
    raise_error "An image has not been set! Please specify a container image that has 'cloudsmith' as the entrypoint."
fi

readonly default_tag="latest"
# TODO: add a "debug" mode where we spit out the specific image and
# commands being used
readonly image="${BUILDKITE_PLUGIN_CLOUDSMITH_IMAGE}:${BUILDKITE_PLUGIN_CLOUDSMITH_TAG:-${default_tag}}"

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
