COMPOSE_USER=$(shell id -u):$(shell id -g)
DOCKER_COMPOSE_CHECK := docker-compose run --rm --user=$(COMPOSE_USER)
PANTS_SHELL_FILTER := ./pants filter --target-type=shell_sources,shunit2_tests :: | xargs ./pants

.DEFAULT_GOAL=all

.PHONY: all
all: format
all: lint
all: test
all: image
all: ## Run (almost!) everything

.PHONY: help
help: ## Print this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n"} \
		 /^[a-zA-Z0-9_-]+:.*?##/ { printf "  %-46s %s\n", $$1, $$2 } \
		 /^##@/ { printf "\n%s\n", substr($$0, 5) } ' \
		 $(MAKEFILE_LIST)
	@printf '\n'

##@ Linting
########################################################################

.PHONY: lint
lint: lint-docker
lint: lint-hcl
lint: lint-plugin
lint: lint-shell
lint: ## Perform lint checks on all files

.PHONY: lint-docker
lint-docker: ## Lint Dockerfiles
	./pants filter --target-type=docker_image :: | xargs ./pants lint

.PHONY: lint-hcl
lint-hcl: ## Lint HCL files
	$(DOCKER_COMPOSE_CHECK) hcl-linter

.PHONY: lint-plugin
lint-plugin: ## Lint the Buildkite plugin metadata
	$(DOCKER_COMPOSE_CHECK) plugin-linter

.PHONY: lint-shell
lint-shell: ## Lint shell scripts
	$(PANTS_SHELL_FILTER) lint

##@ Formatting
########################################################################

.PHONY: format
format: format-hcl
format: format-shell
format: ## Automatically format all code

.PHONY: format-hcl
format-hcl: ## Format HCL files
	$(DOCKER_COMPOSE_CHECK) hcl-formatter

.PHONY: format-shell
format-shell: ## Format shell scripts
	$(PANTS_SHELL_FILTER) fmt

##@ Testing
########################################################################
.PHONY: test
test: test-plugin
test: test-shell
test: ## Run all tests

.PHONY: test-plugin
test-plugin: ## Test the Buildkite plugin locally (does *not* run a Buildkite pipeline)
	$(DOCKER_COMPOSE_CHECK) plugin-tester

.PHONY: test-shell
test-shell: ## Unit test shell scripts
	$(PANTS_SHELL_FILTER) test

##@ Container Images
########################################################################

.PHONY: image
image: ## Build the Cloudsmith container image
	docker buildx bake

.PHONY: image-push
image-push: ## Build *and* push the Cloudsmith container image to a repository
	docker buildx bake --push
