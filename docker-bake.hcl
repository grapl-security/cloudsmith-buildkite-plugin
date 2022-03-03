group "default" {
  targets = ["cloudsmith-cli"]
}

variable "CLOUDSMITH_CLI_VERSION" {
  default = "0.31.1"
}

target "cloudsmith-cli" {
  context    = "."
  dockerfile = "Dockerfile"
  args = {
    "CLOUDSMITH_CLI_VERSION" = "${CLOUDSMITH_CLI_VERSION}"
  }
  labels = {
    "org.opencontainers.image.authors" = "https://graplsecurity.com"
    "org.opencontainers.image.source"  = "https://github.com/grapl-security/cloudsmith-buildkite-plugin",
    "org.opencontainers.image.vendor"  = "Grapl, Inc."
  }
  tags = [
    "docker.cloudsmith.io/grapl/raw/cloudsmith-cli:latest",
    "docker.cloudsmith.io/grapl/raw/cloudsmith-cli:${CLOUDSMITH_CLI_VERSION}"
  ]
}
