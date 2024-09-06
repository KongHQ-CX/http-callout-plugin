MDIR = ./
PONGO_VERSION := 2.12.0
KONG_VERSION := 3.4.3.12
# DOCKER_DEFAULT_PLATFORM := linux/amd64

.PHONY: build-venv
build-venv:
	@mkdir -p .venv/bin
	@echo "DOWNLOADING PONGO..."
	@git clone https://github.com/Kong/kong-pongo.git --depth 1 --branch $(PONGO_VERSION) .venv/pongo || true
	@ln -sf $$(pwd)/.venv/pongo/pongo.sh $$(pwd)/.venv/bin/pongo
	@echo "export PATH=$$PATH:$$(pwd)/.venv/bin" > .venv/env
	@echo "export KONG_VERSION=$(KONG_VERSION)" >> .venv/env
	# @echo "export DOCKER_DEFAULT_PLATFORM=$(DOCKER_DEFAULT_PLATFORM)" >> .venv/env
	@echo "BUILDING PONGO IMAGE"
	@. .venv/env && pongo build

.PHONY: package
package: build-venv
	@echo "PACKAGING PLUGINS AND LIBRARIES"
	@. .venv/env && pongo pack
	@mkdir -p build/out/
	@mv ./*.all.rock build/out

.PHONY: expunge
expunge:
	@echo "! DELETING VIRTUAL ENV"
	@.venv/bin/pongo down || true
	@rm -rf ./.venv
	@echo "! DELETING BUILT PACKAGES"
	@rm -rf ./build
	@echo "! DELETING PONGO IMAGE"
	@docker image rm -f kong-pongo-$(PONGO_VERSION):$(KONG_VERSION) > /dev/null 2>&1 || true

.PHONY: test
test: build-venv
	@. .venv/env && pongo run

# Clone repository first, then run 'make install'
.PHONY: install
install:
	@mkdir -p /usr/local/share/lua/5.1/kong/plugins/http-callout
	@cp -R kong/plugins/http-callout/*.lua /usr/local/share/lua/5.1/kong/plugins/http-callout/
