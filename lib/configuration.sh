#!/usr/bin/env bash

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/log.sh"

# Return this plugin's configuration as a JSON string.
#
# Assumes that there is only a single instance of this plugin
# configured for the current job (which is a valid assumption at this
# point).
plugin_configuration() {
    jq --raw-output --exit-status '.
       | map(to_entries
       |     .[]
       |     select(.key | test("grapl-security/cloudsmith")))
       | .[0].value' <<< "${BUILDKITE_PLUGINS}" ||
        raise_error "Could not parse JSON plugin configuration for grapl-security/cloudsmith plugin from environment:\n$(jq '.' <<< "${BUILDKITE_PLUGINS}")"
}

# Retrieve the packages manifest object from a configured file or
# from explicitly-registered packages in the plugin configuration.
get_packages() {
    local -r _config="${1}"

    if the_file=$(jq --raw-output --exit-status '.promote.packages_file' <<< "${_config}"); then
        # we were given a file; read the packages from it
        if [ -e "${the_file}" ]; then
            jq --raw-output --exit-status '.' "${the_file}" ||
                raise_error "promote.packages_file '${the_file}' does not appear to contain valid JSON:\n$(cat "${the_file}")"
        else
            raise_error "promote.packages_file '${the_file}' does not appear to exist; did you forget to add it?"
        fi
    else
        # read the packages object from the configuration
        jq --raw-output --exit-status '.promote.packages' <<< "${_config}" ||
            raise_error "promote.packages could not found"
    fi
}

get_org() {
    _get_configuration_value ".promote.org" "${1}"
}

get_from() {
    _get_configuration_value ".promote.from" "${1}"
}

get_to() {
    _get_configuration_value ".promote.to" "${1}"
}

_get_configuration_value() {
    local -r _key_path="${1}"
    local -r _config="${2}"

    if ! value=$(jq --raw-output --exit-status "${_key_path}" <<< "${_config}"); then
        raise_error "Expected value at '${_key_path}'\n$(jq '.' <<< "${_config}")"
    fi
    echo "${value}"
}
