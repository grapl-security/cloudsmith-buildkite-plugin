COMPOSE_USER=$(shell id -u):$(shell id -g)

RUN_CHECK := docker-compose run --rm --user=${COMPOSE_USER}

.DEFAULT_GOAL=all

# Formatting
########################################################################

.PHONY: format
format: format-hcl format-shell

.PHONY: format-hcl
format-hcl:
	${RUN_CHECK} hcl-formatter

.PHONY: format-shell
format-shell:
	./pants fmt ::

# Linting
########################################################################

.PHONY: lint
lint: lint-docker lint-hcl lint-shell lint-plugin

.PHONY: lint-docker
lint-docker:
	./pants filter --target-type=docker_image :: | xargs ./pants lint

.PHONY: lint-hcl
lint-hcl:
	${RUN_CHECK} hcl-linter

.PHONY: lint-shell
lint-shell:
	./pants filter --target-type=shell_sources,shunit2_tests :: | xargs ./pants lint

.PHONY: lint-plugin
lint-plugin:
	${RUN_CHECK} plugin-linter

# Testing
########################################################################
.PHONY: test
test: test-shell test-plugin

.PHONY: test-shell
test-shell:
	./pants test ::

.PHONY: test-plugin
test-plugin:
	${RUN_CHECK} plugin-tester

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
