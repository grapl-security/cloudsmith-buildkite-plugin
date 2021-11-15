#!/usr/bin/env bash

plugin_configuration_with_explicit_packages() {
    cat << EOF
[
  {"grapl-security/vault-login#v0.1.0": {}},
  {"grapl-security/vault-env#v0.1.0": {}},
  {
    "grapl-security/cloudsmith-buildkite-plugin#deadbeef": {
      "promote": {
        "to": "releases",
        "org": "grapl",
        "from": "raw",
        "packages": {
          "foo": "1.2.3",
          "bar": "2.3.4"
        }
      }
    }
  },
  {"superawesomesauce/something-nifty-that-definitely-exists-yup#1.0.0": {}}
]
EOF
}

plugin_configuration_with_packages_file() {
    cat << EOF
[
  {"grapl-security/vault-login#v0.1.0": {}},
  {"grapl-security/vault-env#v0.1.0": {}},
  {
    "grapl-security/cloudsmith-buildkite-plugin#deadbeef": {
      "promote": {
        "to": "releases",
        "org": "grapl",
        "from": "raw",
        "packages_file": "${SHUNIT_TMPDIR}/packages.json"
      }
    }
  },
  {"superawesomesauce/something-nifty-that-definitely-exists-yup#1.0.0": {}}
]
EOF
}

oneTimeSetUp() {
    # shellcheck source-path=SCRIPTDIR
    source "$(dirname "${BASH_SOURCE[0]}")/configuration.sh"
}

setUp() {
    unset BUILDKITE_PLUGINS
}

tearDown() {
    unset BUILDKITE_PLUGINS
}

test_plugin_configuration_returns_proper_result() {

    BUILDKITE_PLUGINS=$(plugin_configuration_with_explicit_packages)

    expected=$(
        cat << EOF
{
  "promote": {
    "to": "releases",
    "org": "grapl",
    "from": "raw",
    "packages": {
      "foo": "1.2.3",
      "bar": "2.3.4"
    }
  }
}
EOF
    )

    output="$(plugin_configuration)"
    assertEquals "Did not retrieve the expected configuration!" \
        "$(jq -r '.' <<< "${expected}")" \
        "$(jq -r '.' <<< "${output}")"
}

test_get_packages_from_explicit_configuration() {
    BUILDKITE_PLUGINS=$(plugin_configuration_with_explicit_packages)
    expected=$(
        cat << EOF
{
    "foo": "1.2.3",
    "bar": "2.3.4"
}
EOF
    )

    configuration=$(plugin_configuration)
    output="$(get_packages "${configuration}")"

    assertEquals "Did not retrieve the expected packages!" \
        "$(jq -r '.' <<< "${expected}")" \
        "$(jq -r '.' <<< "${output}")"
}

test_get_packages_from_file() {
    expected=$(
        cat << EOF
{
    "my_package": "1.1.1",
    "your_package": "2.2.2",
    "someone_elses_package": "3.3.3"
}
EOF
    )

    echo "${expected}" > "${SHUNIT_TMPDIR}/packages.json"

    BUILDKITE_PLUGINS="$(plugin_configuration_with_packages_file)"

    configuration=$(plugin_configuration)
    output="$(get_packages "${configuration}")"

    assertEquals "Did not retrieve the expected packages!" \
        "$(jq -r '.' <<< "${expected}")" \
        "$(jq -r '.' <<< "${output}")"

}

test_get_org_works() {
    actual="$(get_org '{"promote": {"org": "my-org"}}')"
    expected="my-org"
    assertEquals "${expected}" "${actual}"
}

test_get_org_fails_with_missing_value() {
    actual="$(get_org '{"promote": {"stuff": "blah"}}' 2>&1)"
    assertEquals "'get_org' should have failed" 1 $?
    expected_error_message="Expected value at '.promote.org'"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_from_works() {
    actual="$(get_from '{"promote": {"org": "my-org", "from": "source-repo"}}')"
    expected="source-repo"
    assertEquals "${expected}" "${actual}"
}

test_get_from_fails_with_missing_value() {
    actual="$(get_from '{"promote": {"org": "my-org"}}' 2>&1)"
    assertEquals "'get_from' should have failed" 1 $?
    expected_error_message="Expected value at '.promote.from'"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}

test_get_to_works() {
    actual="$(get_to '{"promote": {"org": "my-org", "from": "source-repo", "to": "dest-repo"}}')"
    expected="dest-repo"
    assertEquals "${expected}" "${actual}"
}

test_get_to_fails_with_missing_value() {
    actual="$(get_to '{"promote": {"org": "my-org", "from": "source-repo"}}' 2>&1)"
    assertEquals "'get_to' should have failed" 1 $?
    expected_error_message="Expected value at '.promote.to'"
    assertContains "Did not find expected message in '${actual}'" "${actual}" "${expected_error_message}"
}
