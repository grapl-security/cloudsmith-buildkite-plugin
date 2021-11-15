group "default" {
  targets = ["cloudsmith-cli"]
}

variable "CLOUDSMITH_CLI_VERSION" {
  default = "0.30.0"
}

target "cloudsmith-cli" {
  context    = "."
  dockerfile = "Dockerfile"
  args = {
    "CLOUDSMITH_CLI_VERSION" = "${CLOUDSMITH_CLI_VERSION}"
  }
  tags = [
    "docker.cloudsmith.io/grapl/raw/cloudsmith-cli:latest",
    "docker.cloudsmith.io/grapl/raw/cloudsmith-cli:${CLOUDSMITH_CLI_VERSION}"
  ]
}

########################################################################

group "testing" {
  targets = ["cloudsmith-buildkite-plugin-verify-test"]
}

variable "BUILDKITE_BUILD_ID" {
  default = "not-running-in-buildkite"
}

# If you change any values in here, make sure to make the
# corresponding changes, if any, to .buildkite/plugin.verify.yml and
# .buildkite/scripts/verify_promotion.sh
target "cloudsmith-buildkite-plugin-verify-test" {
  context    = "."
  dockerfile = "Dockerfile.testing"
  args = {
    "BUILDKITE_BUILD_ID" = "${BUILDKITE_BUILD_ID}"
  }
  tags = [
    "docker.cloudsmith.io/grapl/testing-stage1/cloudsmith-buildkite-plugin-verify-test:${BUILDKITE_BUILD_ID}"
  ]
}
