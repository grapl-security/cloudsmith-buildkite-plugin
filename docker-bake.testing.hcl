# If you change any values in here, make sure to make the
# corresponding changes, if any, to .buildkite/plugin.verify.yml,
# .buildkite/plugin.merge.build-container.yml and
# .buildkite/scripts/verify_promotion.sh

variable "BUILDKITE_BUILD_ID" {
  # Containers will use the Build ID as a unique tag
  default = "not-running-in-buildkite"
}

# Both images we're going to build are basically the same; they just
# have different tags. As such, we can define a base image for them to
# inherit. You should not build this target by itself.
target "base" {
  context    = "."
  dockerfile = "Dockerfile.testing"
  args = {
    "BUILDKITE_BUILD_ID" = "${BUILDKITE_BUILD_ID}"
  }
}

# Use this image in the verify pipeline for testing.
target "verify-image" {
  inherits = ["base"]
  tags = [
    "docker.cloudsmith.io/grapl/testing-stage1/cloudsmith-buildkite-plugin-verify-test:${BUILDKITE_BUILD_ID}"
  ]
}

# Use this image in the merge pipeline for testing.
target "merge-image" {
  inherits = ["base"]
  tags = [
    "docker.cloudsmith.io/grapl/testing-stage1/cloudsmith-buildkite-plugin-merge-test:${BUILDKITE_BUILD_ID}"
  ]
}
