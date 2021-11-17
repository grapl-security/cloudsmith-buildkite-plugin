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

# The particular image we're querying will depend on whether we're in
# the verify pipeline or the merge pipeline; see
# docker-bake.testing.hcl for possible values.
readonly image_name="${1}"

# We need to know if we're verifying a move or a copy, so we can know
# whether or not to fail if the package is left behind in the source
# repository.
readonly action="${2}"

# All images are expected to be tagged with the current build ID,
# (also defined in docker-bake.testing.hcl).
readonly image_tag="${BUILDKITE_BUILD_ID}"
readonly fully_qualified_image_name="${image_name}:${image_tag}"

readonly from_repository=testing-stage1
readonly to_repository=testing-stage2

query() {
    local -r _repo="${1}"

    # In this case, we don't care about the error message that
    # `get_unique_identifier` can return.
    get_unique_identifier grapl "${_repo}" "name:${image_name} version:${image_tag}" 2> /dev/null
}

echo "--- :cloudsmith: Verifying ${action} from source repository"
case "${action}" in
    move)
        if package_id=$(query "${from_repository}"); then
            raise_error "Should not have found ${fully_qualified_image_name} in ${from_repository} after a move, but found package with ID '${package_id}'!"
        else
            echo "--- :cloudsmith: Did not find ${fully_qualified_image_name} in ${from_repository} after a move, as expected"
        fi
        ;;
    copy)
        if ! package_id=$(query "${from_repository}"); then
            raise_error "Should have found ${fully_qualified_image_name} in ${from_repository} repository after a copy, but didn't!"
        else
            echo "--- :cloudsmith: Found ${fully_qualified_image_name} (ID = ${package_id}) in ${from_repository} after a copy, as expected"
        fi
        ;;
    *)
        raise_error "Unrecognized action '${action}' (should be 'move' or 'copy')"
        ;;
esac

# Whether or not we were copying or moving, the package should always
# be found in the destination repository
echo "--- :cloudsmith: Verifying promotion into destination repository"
if package_id=$(query "${to_repository}"); then
    echo "--- :cloudsmith: Found ${fully_qualified_image_name} (ID = '${package_id}') in ${to_repository}, as expected"
else
    raise_error "Should have found ${fully_qualified_image_name} in ${to_repository}, but did not!"
fi
