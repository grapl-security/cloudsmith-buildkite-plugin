#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# Generate a series of Cloudsmith query strings to use in `cloudsmith
# package list` call.
#
# Note that we wrap both the name and the version in anchors (`^...$`)
# to force them to match exactly. Otherwise, you can end up with
# multiple results if you have similarly-named packages with the same
# version (e.g. "foo 1.2.3" and "foobar 1.2.3").
packages_to_queries() {
    local -r _packages="${1}"

    jq --raw-output --exit-status '
        to_entries
        | .[]
        | "name:^" + .key + "$ " + "version:^" + .value + "$"' \
        <<< "${_packages}" ||
        raise_error "Problem converting package specifications to Cloudsmith query strings:\n${_packages}"
}

# Retrieve the unique identifier of a given package; this is needed
# for promotion.
#
# Accepts a query string that is implicitly assumed to refer to a
# single package instance.
#
# See https://help.cloudsmith.io/docs/identifying-a-package for
# further details.
get_unique_identifier() {
    local -r _org="${1}"
    local -r _from_repo="${2}"
    local -r _query="${3}"

    # Unfortunately, we can't use --debug and --verbose here due to
    # mingling of stdout and stderr in the CLI itself; it pollutes the
    # JSON we're trying to capture :(
    if ! result=$(cloudsmith list packages \
        "${_org}/${_from_repo}" \
        --query="${_query}" \
        --output-format=json); then
        raise_error "Cloudsmith list packages failed!\n${result}"
    fi

    if ! jq --exit-status '.' <<< "${result}" &> /dev/null; then
        raise_error "Could not parse 'cloudsmith list packages' output as JSON:\n${result}"
    fi

    if len=$(jq --raw-output --exit-status '(.data // empty) | length' <<< "${result}"); then
        if [ 1 == "${len}" ]; then
            jq --raw-output --exit-status '.data[0].slug_perm' <<< "${result}" ||
                raise_error "Unexpected missing 'slug_perm' key of search result:\n$(jq '.data[0]' <<< "${result}")"
        else
            raise_error "Expected query '${_query}' to return a single package, but it returned ${len}"
        fi
    else
        raise_error "Unexpected missing 'data' key to 'cloudsmith list packages' output:\n$(jq '.' <<< "${result}")"
    fi
}

# Promote a package from one repository to another
promote() {
    local -r _org="${1}"
    local -r _from_repo="${2}"
    local -r _to_repo="${3}"
    local -r _slug="${4}"
    local -r _action="${5}"

    case "${_action}" in
        move)
            cloudsmith move \
                --yes \
                "${_org}/${_from_repo}/${_slug}" \
                "${_to_repo}"
            ;;
        copy)
            cloudsmith copy \
                "${_org}/${_from_repo}/${_slug}" \
                "${_to_repo}"
            ;;
        *)
            # Note: we should never get here because this value should
            # have been validated elsewhere
            raise_error "Invalid action '${_action}'\nIf you are seeing this message, please report it as a bug!"
            ;;
    esac
}
