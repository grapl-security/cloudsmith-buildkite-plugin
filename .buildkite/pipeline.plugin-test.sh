#!/usr/bin/env bash

set -euo pipefail

# We're encapsulating these steps in a script because we need to run
# them in a few different variations, and it's a lot to
# copy-and-paste. Instead, we'll just parameterize them in a script,
# and then upload the steps.

# shellcheck source-path=SCRIPTDIR
source "$(dirname "${BASH_SOURCE[0]}")/../lib/log.sh"

readonly action="${1}" # copy or move

# E.g., cloudsmith-buildkite-plugin/verify or cloudsmith-buildkite-plugin/merge
if [[ "${BUILDKITE_PIPELINE_NAME}" =~ "verify" ]]; then
    pipeline="verify"
elif [[ "${BUILDKITE_PIPELINE_NAME}" =~ "merge" ]]; then
    pipeline="merge"
else
    raise_error "Unrecognized pipeline; expected a verify or merge pipeline, but got '${BUILDKITE_PIPELINE_NAME}'"
fi

cat << EOF
---
steps:
  - group: ":hammer_and_wrench: Integration Tests"
    steps:
      - label: ":cloudsmith::docker: Upload '${action}' container"
        key: test-${action}-upload
        command:
          - docker buildx bake ${pipeline}-${action}-image --file=docker-bake.testing.hcl --push
        plugins:
          - grapl-security/vault-login#v0.1.3
          - grapl-security/vault-env#v0.1.0:
              secrets:
                - CLOUDSMITH_API_KEY
          - docker-login#v2.1.0:
              username: grapl-cicd
              password-env: CLOUDSMITH_API_KEY
              server: docker.cloudsmith.io
        agents:
          queue: "docker"

      - label: ":cloudsmith::buildkite: Promote via ${action}"
        key: promotion-${action}-test
        depends_on: test-${action}-upload
        plugins:
          - grapl-security/vault-login#v0.1.3
          - grapl-security/vault-env#v0.1.0:
              secrets:
                - CLOUDSMITH_API_KEY
          - grapl-security/cloudsmith#${BUILDKITE_COMMIT}:
              promote:
EOF

if [ "${pipeline}" = "merge" ]; then
    # If we're in the merge pipeline, then we want to use the new
    # Cloudsmith container.
    #
    # NOTE: The spacing in this heredoc is *important* because it's
    # YAML
    cat << EOF
                image: docker.cloudsmith.io/grapl/raw/cloudsmith-cli
                tag: latest
EOF
fi

cat << EOF
                org: grapl
                action: ${action}
                from: testing-stage1
                to: testing-stage2
                packages:
                  cloudsmith-buildkite-plugin-${pipeline}-${action}-test: ${BUILDKITE_BUILD_ID}
        agents:
          queue: "docker"

      - label: ":cloudsmith::white_check_mark: Verify ${action}"
        key: verify-promotion-${action}
        depends_on: promotion-${action}-test
        command:
          - .buildkite/scripts/verify_promotion.sh "cloudsmith-buildkite-plugin-${pipeline}-${action}-test" "${action}"
        plugins:
          - grapl-security/vault-login#v0.1.3
          - grapl-security/vault-env#v0.1.0:
              secrets:
                - CLOUDSMITH_API_KEY
        agents:
          queue: "docker"

EOF
