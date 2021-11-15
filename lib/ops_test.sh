#!/usr/bin/env bash

# mock `cloudsmith` binary
#
# This prevents the actual `cloudsmith` binary from being executed during
# these tests. Every invocation is logged to a file.
#
# To make assertions, simply inspect the contents of the file to
# ensure that the expected commands _would_ have been invoked.

cloudsmith() {
    echo "${FUNCNAME[0]} $*" >> "${ALL_COMMANDS}"

    case "$*" in
        list\ packages\ schmapl/no-packages*)
            cat << EOF
{
  "data": []
}
EOF
            ;;

        list\ packages\ schmapl/too-many-packages*)
            # The contents aren't important; just the fact that there
            # are more than one item in `data`
            cat << EOF
{
  "data": [{},{},{}]
}
EOF
            ;;

        list\ packages\ schmapl/missing-slug*)
            cat << EOF
{
  "data": [{"slug": "really-wanted slug_perm as the key"}]
}
EOF
            ;;

        list\ packages\ schmapl/not-json*)
            cat <<< "This is not JSON... did you forget to add --output-format=json?"
            ;;

        list\ packages\ schmapl/wrong-structure*)
            cat << EOF
{
    "stuff": []
}
EOF
            ;;

        list\ packages\ schmapl/failure*)
            echo "Haha, this failed"
            exit 1
            ;;

        list\ packages\ schmapl/bucket-o-stuff*)
            cat << EOF
{
  "data": [
    {
      "architectures": [
        {
          "description": null,
          "name": "amd64"
        }
      ],
      "cdn_url": null,
      "checksum_md5": "",
      "checksum_sha1": "",
      "checksum_sha256": "",
      "checksum_sha512": "",
      "dependencies_checksum_md5": null,
      "description": null,
      "distro": null,
      "distro_version": null,
      "downloads": 6,
      "epoch": null,
      "extension": "",
      "filename": "my-amazing-service",
      "files": [],
      "format": "docker",
      "format_url": "https://api.cloudsmith.io/v1/formats/docker/",
      "identifier_perm": "8QzX5yKpxFLz",
      "indexed": true,
      "is_sync_awaiting": false,
      "is_sync_completed": true,
      "is_sync_failed": false,
      "is_sync_in_flight": false,
      "is_sync_in_progress": false,
      "license": null,
      "name": "my-amazing-service",
      "namespace": "schmapl",
      "namespace_url": "https://api.cloudsmith.io/v1/namespaces/schmapl/",
      "num_files": 0,
      "package_type": "1",
      "release": null,
      "repository": "bucket-o-stuff",
      "repository_url": "https://api.cloudsmith.io/v1/repos/schmapl/bucket-o-stuff/",
      "security_scan_completed_at": "2021-11-10T17:06:35.233244Z",
      "security_scan_started_at": null,
      "security_scan_status": "Security Scanning Failed",
      "security_scan_status_updated_at": "2021-11-10T17:06:35.233234Z",
      "self_html_url": "https://cloudsmith.io/~schmapl/repos/bucket-o-stuff/packages/detail/docker/my-amazing-service/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/a=amd64;xpo=linux/",
      "self_url": "https://api.cloudsmith.io/v1/packages/schmapl/bucket-o-stuff/8QzX5yKpxFLz/",
      "signature_url": null,
      "size": 52302313,
      "slug": "my-amazing-service-ZZZ",
      "slug_perm": "8QzX5yKpxFLz",
      "stage": "9",
      "stage_str": "Fully Synchronised",
      "stage_updated_at": "2021-11-10T17:05:15.228098Z",
      "status": "4",
      "status_reason": null,
      "status_str": "Completed",
      "status_updated_at": "2021-11-10T17:05:15.224372Z",
      "status_url": "https://api.cloudsmith.io/v1/packages/schmapl/bucket-o-stuff/8QzX5yKpxFLz/status/",
      "subtype": null,
      "summary": null,
      "sync_finished_at": "2021-11-10T17:05:15.228092Z",
      "sync_progress": 100,
      "tags": {
        "version": [
          "1.2.3"
        ]
      },
      "tags_immutable": {},
      "type_display": "image",
      "uploaded_at": "2021-11-10T17:05:04.563209Z",
      "uploader": "uploadey-the-amazing-uploader",
      "uploader_url": "https://api.cloudsmith.io/v1/users/profile/uploadey-the-amazing-uploader/",
      "version": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "version_orig": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "vulnerability_scan_results_url": "https://api.cloudsmith.io/v1/vulnerabilities/schmapl/bucket-o-stuff/8QzX5yKpxFLz/"
    }
  ],
  "meta": {
    "pagination": {
      "page": 1,
      "page_max": 1,
      "page_results_from": 1,
      "page_results_len": 0,
      "page_results_to": 1,
      "page_size": 30,
      "results_total": 1
    }
  }
}
EOF
            ;;
        *) ;;
    esac
}

recorded_commands() {
    if [ -f "${ALL_COMMANDS}" ]; then
        cat "${ALL_COMMANDS}"
    fi
}

oneTimeSetUp() {
    # shellcheck source-path=SCRIPTDIR
    source "$(dirname "${BASH_SOURCE[0]}")/ops.sh"
    export ALL_COMMANDS="${SHUNIT_TMPDIR}/all_commands"
}

setUp() {
    # Ensure any recorded commands from the last test are removed so
    # we start with a clean slate.
    rm -f "${ALL_COMMANDS}"
}

test_packages_to_queries_generates_the_expected_queries() {
    packages=$(
        cat << EOF
{
    "foo": "1.2.3",
    "bar": "2.3.4"
}
EOF
    )

    expected=$(
        cat << EOF
name:foo version:1.2.3
name:bar version:2.3.4
EOF
    )
    output="$(packages_to_queries "${packages}")"
    assertEquals "${expected}" "${output}"
}

test_slug() {
    expected_commands=$(
        cat << EOF
cloudsmith list packages schmapl/bucket-o-stuff --query="name:my-amazing-service version:1.2.3" --output-format=json
EOF
    )

    actual=$(get_unique_identifier schmapl bucket-o-stuff '"name:my-amazing-service version:1.2.3"')
    expected=8QzX5yKpxFLz

    assertEquals "The expected cloudsmith commands were not run" \
        "${expected_commands}" \
        "$(recorded_commands)"
    assertEquals "The expected slug was not extracted" \
        "${expected}" \
        "${actual}"
}

test_promote() {

    expected_commands=$(
        cat << EOF
cloudsmith promote --yes schmapl/bucket-o-stuff/8QzX5yKpxFLz validated-bucket-o-stuff
EOF
    )

    promote schmapl bucket-o-stuff validated-bucket-o-stuff 8QzX5yKpxFLz

    assertEquals "The expected cloudsmith commands were not run" \
        "${expected_commands}" \
        "$(recorded_commands)"
}

test_packages_to_queries_works_with_valid_json() {

    expected=$(
        cat << EOF
name:foo version:1.2.3
name:barf version:4.5.6
EOF
    )
    actual="$(packages_to_queries '{"foo": "1.2.3", "barf": "4.5.6"}')"

    assertEquals "${expected}" "${actual}"
}

test_packages_to_queries_fails_with_wrong_json() {
    # Capture stderr to get access to the error message so we can make
    # assertions about it.
    actual="$(packages_to_queries '["foo", "1.2.3", "barf", "4.5.6"]' 2>&1)"

    # That invocation should have failed (exit code 1)
    assertEquals "'packages_to_queries' should have failed" 1 $?

    expected_error_message="Problem converting package specifications to Cloudsmith query strings"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_query_identifies_no_packages() {

    actual="$(get_unique_identifier schmapl no-packages 'name:blah version:1.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Expected query 'name:blah version:1.0.0' to return a single package, but it returned 0"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_query_identifies_multiple_packages() {

    actual="$(get_unique_identifier schmapl too-many-packages 'name:foobar version:2.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Expected query 'name:foobar version:2.0.0' to return a single package, but it returned 3"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_slug_perm_key_is_not_found() {

    actual="$(get_unique_identifier schmapl missing-slug 'name:foo version:3.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Unexpected missing 'slug_perm' key of search result"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_query_does_not_return_json() {
    actual="$(get_unique_identifier schmapl not-json 'name:bad version:4.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Could not parse 'cloudsmith list packages' output as JSON"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_json_is_not_correct_structure() {
    actual="$(get_unique_identifier schmapl wrong-structure 'name:super-bad version:5.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Unexpected missing 'data' key to 'cloudsmith list packages' output"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_unique_identifier_fails_if_json_is_not_correct_structure() {
    actual="$(get_unique_identifier schmapl failure 'name:objectively-horrible version:6.0.0' 2>&1)"

    assertEquals "'get_unique_identifier' should have failed" 1 $?

    expected_error_message="Cloudsmith list packages failed!"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}
