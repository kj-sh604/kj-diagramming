SHELL := /bin/sh

IMAGE ?= kj-diagramming:latest
BUILD_DIR := excalidraw-app/build
PROJECT_MARKER := excalidraw-app/App.tsx
CONTAINER_ENGINE := $(shell if command -v docker >/dev/null 2>&1; then printf '%s' docker; elif command -v podman >/dev/null 2>&1; then printf '%s' podman; fi)

.PHONY: help build clean container check-yarn check-container-engine check-build-dir

help:
	@echo "targets:"
	@echo "  make build      build static assets into $(BUILD_DIR)"
	@echo "  make clean      rm $(BUILD_DIR) (with checks)"
	@echo "  make container  build kj-diagramming image"

check-yarn:
	@if ! command -v yarn >/dev/null 2>&1; then \
		echo "warning: yarn is not installed."; \
		echo "install yarn to use: make build"; \
	fi

check-container-engine:
	@if [ -z "$(CONTAINER_ENGINE)" ]; then \
		echo "error: neither docker nor podman is installed."; \
		echo "install docker or podman, then run: make container"; \
		exit 1; \
	fi
	@echo "using container engine: $(CONTAINER_ENGINE)"

check-build-dir:
	@if [ ! -d "$(BUILD_DIR)" ]; then \
		echo "error: $(BUILD_DIR) is missing."; \
		echo "run: make build"; \
		exit 1; \
	fi

build:
	@if ! command -v yarn >/dev/null 2>&1; then \
		echo "error: yarn is not installed."; \
		echo "install yarn, then run: make build"; \
		exit 1; \
	fi
	@echo "building static assets into $(BUILD_DIR)..."
	@NODE_ENV=production yarn build:app:docker

clean:
	@if [ -f "$(PROJECT_MARKER)" ] || [ -d "$(BUILD_DIR)" ]; then \
		if [ -d "$(BUILD_DIR)" ]; then \
			echo "removing $(BUILD_DIR)..."; \
			rm -rf "$(BUILD_DIR)"; \
		else \
			echo "nothing to clean: $(BUILD_DIR) does not exist."; \
		fi; \
	else \
		echo "safety check failed: not in kj-diagramming repo root and $(BUILD_DIR) was not found."; \
		echo "refusing to run rm."; \
		exit 1; \
	fi

container: check-yarn check-container-engine clean build
	@echo "building image $(IMAGE)..."
	@$(CONTAINER_ENGINE) build -f Dockerfile -t "$(IMAGE)" .