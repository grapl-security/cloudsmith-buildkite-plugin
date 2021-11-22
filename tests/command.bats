#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
# export DOCKER_STUB_DEBUG=/dev/tty

# The constant part of the Docker `cloudsmith` invocation; useful for stubbing
readonly CLOUDSMITH="run --init --rm --env=CLOUDSMITH_API_KEY -- docker.cloudsmith.io/grapl/releases/cloudsmith-cli:latest"

setup() {
    TEMPFILE=$(mktemp /tmp/tempfile.json.XXXXXX)
    export TEMPFILE
}

teardown() {
    unset BUILDKITE_PLUGINS
    rm -f "${TEMPFILE}"
    unset TEMPFILE
}

@test "works with a single package" {
    export BUILDKITE_PLUGINS=$(cat << EOF
[
  {
    "grapl-security/cloudsmith-buildkite-plugin#deadbeef": {
      "promote": {
        "org": "grapl",
        "from": "raw",
        "to": "releases",
        "action": "move",
        "packages": {
          "foo": "1.2.3"
        }
      }
    }
  }
]
EOF
           )

    stub docker \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:foo version:1.2.3\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"fooXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/fooXXX releases : echo 'Moved foo'" \

    run "${PWD}/hooks/command"
    assert_success

    assert_output --partial "Promoting packages from grapl/raw to grapl/releases via move"
    assert_output --partial "Processing query 'name:foo version:1.2.3'"
    assert_output --partial "Moved foo"

    unstub docker
}

@test "works with multiple packages" {
    export BUILDKITE_PLUGINS=$(cat << EOF
[
  {
    "grapl-security/cloudsmith-buildkite-plugin#deadbeef": {
      "promote": {
        "org": "grapl",
        "from": "raw",
        "to": "releases",
        "action": "move",
        "packages": {
          "foo": "1.2.3",
          "bar": "2.3.4",
          "baz": "3.4.5"
        }
      }
    }
  }
]
EOF
           )

    stub docker \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:foo version:1.2.3\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"fooXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/fooXXX releases : echo 'Moved foo'" \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:bar version:2.3.4\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"barXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/barXXX releases : echo 'Moved bar'" \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:baz version:3.4.5\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"bazXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/bazXXX releases : echo 'Moved baz'"

    run "${PWD}/hooks/command"
    assert_success

    assert_output --partial "Promoting packages from grapl/raw to grapl/releases via move"
    assert_output --partial "Processing query 'name:foo version:1.2.3'"
    assert_output --partial "Processing query 'name:bar version:2.3.4'"
    assert_output --partial "Processing query 'name:baz version:3.4.5'"
    assert_output --partial "Moved foo"
    assert_output --partial "Moved bar"
    assert_output --partial "Moved baz"

    unstub docker
}

@test "works with a file of multiple packages" {
    export BUILDKITE_PLUGINS=$(cat << EOF
[
  {
    "grapl-security/cloudsmith-buildkite-plugin#deadbeef": {
      "promote": {
        "org": "grapl",
        "from": "raw",
        "to": "releases",
        "action": "move",
        "packages_file": "${TEMPFILE}"
      }
    }
  }
]
EOF
           )

    cat << EOF > "${TEMPFILE}"
{
    "file-foo": "1.2.3",
    "file-bar": "2.3.4",
    "file-baz": "3.4.5"
}
EOF

    stub docker \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:file-foo version:1.2.3\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"fooXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/fooXXX releases : echo 'Moved foo'" \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:file-bar version:2.3.4\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"barXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/barXXX releases : echo 'Moved bar'" \
         "${CLOUDSMITH} list packages grapl/raw --query=\"name:file-baz version:3.4.5\" --output-format=json : echo '{\"data\": [{\"slug_perm\": \"bazXXX\"}]}'" \
         "${CLOUDSMITH} move --yes grapl/raw/bazXXX releases : echo 'Moved baz'"

    run "${PWD}/hooks/command"
    assert_success

    assert_output --partial "Promoting packages from grapl/raw to grapl/releases via move"
    assert_output --partial "Processing query 'name:file-foo version:1.2.3'"
    assert_output --partial "Processing query 'name:file-bar version:2.3.4'"
    assert_output --partial "Processing query 'name:file-baz version:3.4.5'"
    assert_output --partial "Moved foo"
    assert_output --partial "Moved bar"
    assert_output --partial "Moved baz"

    unstub docker
}
