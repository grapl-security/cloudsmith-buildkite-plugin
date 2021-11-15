COMPOSE_USER=$(shell id -u):$(shell id -g)

RUN_CHECK := docker-compose run --rm --user=${COMPOSE_USER}

.DEFAULT_GOAL=all

# Formatting
########################################################################

.PHONY: format
format: format-hcl format-bash

.PHONY: format-hcl
format-hcl:
	${RUN_CHECK} hcl-formatter

.PHONY: format-bash
format-bash:
	./pants fmt ::

# Linting
########################################################################

.PHONY: lint
lint: lint-docker lint-hcl lint-bash lint-plugin

.PHONY: lint-docker
lint-docker:
	${RUN_CHECK} hadolint

.PHONY: lint-hcl
lint-hcl:
	${RUN_CHECK} hcl-linter

.PHONY: lint-bash
lint-bash:
	./pants lint ::

.PHONY: lint-plugin
lint-plugin:
	${RUN_CHECK} plugin-linter

# Testing
########################################################################
.PHONY: test
test: test-bash

.PHONY: test-bash
test-bash:
	./pants test ::

# Containers
########################################################################

.PHONY: image
image:
	docker buildx bake

.PHONY: image-push
image-push:
	docker buildx bake --push

########################################################################

.PHONY: all
all: format lint test image

########################################################################

.PHONY: update-buildkite-shared
update-buildkite-shared: ## Pull in changes from grapl-security/buildkite-common
	git subtree pull --prefix .buildkite/shared git@github.com:grapl-security/buildkite-common.git main --squash
