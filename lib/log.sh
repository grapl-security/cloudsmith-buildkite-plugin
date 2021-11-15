#!/usr/bin/env bash

log() {
    echo -e "${@}" >&2
}

raise_error() {
    log "--- :rotating_light:" "${@}"
    # Yes, these numbers are correct :/
    log "Failed in ${FUNCNAME[1]}() at [${BASH_SOURCE[1]}:${BASH_LINENO[0]}], called from [${BASH_SOURCE[2]}:${BASH_LINENO[1]}]"
    exit 1
}
