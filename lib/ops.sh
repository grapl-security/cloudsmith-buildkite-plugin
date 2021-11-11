#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# Generate a series of Cloudsmith query strings to use in `cloudsmith
# package list` call
packages_to_queries() {
    local -r _packages="${1}"

    jq --raw-output --exit-status '
        to_entries
        | .[]
        | "name:" + .key + " " + "version:" + .value' \
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

    cloudsmith promote \
        --yes \
        "${_org}/${_from_repo}/${_slug}" \
        "${_to_repo}"
}
