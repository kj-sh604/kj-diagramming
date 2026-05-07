SHELL := /bin/sh

IMAGE ?= kj-diagramming:latest
BUILD_DIR := excalidraw-app/build
PROJECT_MARKER := excalidraw-app/App.tsx
CONTAINER_NAME ?= kj-diagramming
HOST_PORT ?= 8000
CONTAINER_PORT ?= 8000
CONTAINER_ENGINE := $(shell if command -v docker >/dev/null 2>&1; then printf '%s' docker; elif command -v podman >/dev/null 2>&1; then printf '%s' podman; fi)

.PHONY: help build clean container serve stop check-yarn check-container-engine check-build-dir

help:
	@echo "targets:"
	@echo "  make build      build static assets into $(BUILD_DIR)"
	@echo "  make clean      rm $(BUILD_DIR) (with checks)"
	@echo "  make container  build kj-diagramming image"
	@echo "  make serve      run $(CONTAINER_NAME) (using $(CONTAINER_ENGINE))"
	@echo "  make stop       stop $(CONTAINER_NAME) (if running on $(CONTAINER_ENGINE))"

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

serve: check-container-engine
	@set -eu; \
	engine="$(CONTAINER_ENGINE)"; \
	name="$(CONTAINER_NAME)"; \
	image="$(IMAGE)"; \
	host_port="$(HOST_PORT)"; \
	container_port="$(CONTAINER_PORT)"; \
	if ! $$engine image inspect "$$image" >/dev/null 2>&1; then \
		echo "error: image $$image was not found."; \
		echo "run: make container"; \
		exit 1; \
	fi; \
	if $$engine ps --format '{{.Names}}' | grep -Fxq "$$name"; then \
		echo "error: container $$name is already running."; \
		echo "run: make stop"; \
		exit 1; \
	fi; \
	if command -v ss >/dev/null 2>&1; then \
		while ss -ltn "sport = :$$host_port" 2>/dev/null | grep -q LISTEN; do \
			host_port=$$((host_port + 1)); \
		done; \
	elif command -v lsof >/dev/null 2>&1; then \
		while lsof -nP -iTCP:$$host_port -sTCP:LISTEN >/dev/null 2>&1; do \
			host_port=$$((host_port + 1)); \
		done; \
	elif command -v netstat >/dev/null 2>&1; then \
		while netstat -ltn 2>/dev/null | awk '{print $$4}' | grep -Eq "[:.]$$host_port$$"; do \
			host_port=$$((host_port + 1)); \
		done; \
	else \
		echo "warning: no port-check utility found (ss, lsof, netstat)."; \
		echo "trying host port $$host_port without pre-check."; \
	fi; \
	echo "starting $$name on http://localhost:$$host_port"; \
	$$engine run -d --rm --name "$$name" -p "$$host_port:$$container_port" "$$image" >/dev/null; \
	echo "started $$name (http://localhost:$$host_port)"

stop: check-container-engine
	@if $(CONTAINER_ENGINE) ps --format '{{.Names}}' | grep -Fxq "$(CONTAINER_NAME)"; then \
		echo "stopping $(CONTAINER_NAME)..."; \
		$(CONTAINER_ENGINE) stop "$(CONTAINER_NAME)" >/dev/null; \
		echo "stopped $(CONTAINER_NAME)."; \
	else \
		echo "container $(CONTAINER_NAME) is not running."; \
	fi