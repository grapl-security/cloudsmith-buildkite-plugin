#!/usr/bin/env bash

# After uploading a container and then promoting it, we must verify
# that the move actually happened as we expected.

set -euo pipefail

# Get access to our cloudsmith "binary"
# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/cloudsmith.sh"
# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/ops.sh"
# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/log.sh"

readonly image_name="cloudsmith-buildkite-plugin-verify-test"
readonly image_tag="${BUILDKITE_BUILD_ID}"
readonly fully_qualified_image_name="${image_name}:${image_tag}"

query() {
    local -r _repo="${1}"

    # In this case, we don't care about the error message that
    # `get_unique_identifier` can return.
    get_unique_identifier grapl "${_repo}" "name:${image_name} version:${image_tag}" 2> /dev/null
}

echo "--- :cloudsmith: Verifying promotion out of source repository"
if package_id=$(query testing-stage1); then
    raise_error "Did not expect to find anything in testing-stage1, but found package with ID '${package_id}'!"
else
    echo "--- :cloudsmith: Did not find ${fully_qualified_image_name} in testing-stage1 repository, as expected"
fi

echo "--- :cloudsmith: Verifying promotion into destination repository"
if package_id=$(query testing-stage2); then
    echo "--- :cloudsmith: Found ${fully_qualified_image_name} in testing-stage2, with ID '${package_id}', as expected"
else
    raise_error "Expected to find ${fully_qualified_image_name} in testing-stage2, but did not!"
fi
