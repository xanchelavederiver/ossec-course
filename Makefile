.DEFAULT_GOAL := labs

DOCKER ?= docker
NPM ?= npm
LABS_IMAGE ?= ossec-labs:local
LAB ?=
LECTURE ?=
HOST ?=
PORT ?=
PASSWORD ?=
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export LAB

.PHONY: labs labs-html labs-pdf labs-image labs-list labs-ruby lectures lectures-slides lecture-dev help

lectures: lectures-slides

lectures-slides:
	$(NPM) --prefix "$(ROOT)/project" run build:all
	$(NPM) --prefix "$(ROOT)/project" run copy:slides

# Example: make lecture-dev LECTURE=02-identity-and-access-management/03-pam HOST=0.0.0.0 PORT=3031
lecture-dev:
	@test -n "$(LECTURE)" || { echo 'Usage: make lecture-dev LECTURE=<topic>/<lecture>' >&2; \
		$(NPM) --prefix "$(ROOT)/project" run --silent list >&2; exit 2; }
	$(NPM) --prefix "$(ROOT)/project" run dev -- "$(LECTURE)" \
		$(if $(HOST),--host "$(HOST)") $(if $(PORT),--port "$(PORT)") \
		$(if $(PASSWORD),--password "$(PASSWORD)")

labs-image:
	$(DOCKER) build -t "$(LABS_IMAGE)" "$(ROOT)/project/build/labs"

define run_labs
	mkdir -p "$(ROOT)/public/labs"
	$(DOCKER) run --rm --network none --user "$$(id -u):$$(id -g)" \
		-e HOME=/tmp -e LAB \
		--mount "type=bind,src=$(ROOT),dst=/workspace,readonly" \
		--mount "type=bind,src=$(ROOT)/public/labs,dst=/workspace/public/labs" \
		-w /workspace "$(LABS_IMAGE)" $(1)
endef

labs: labs-image
	$(call run_labs,ruby project/scripts/labs.rb --format all)

labs-html: labs-image
	$(call run_labs,ruby project/scripts/labs.rb --format html)

labs-pdf: labs-image
	$(call run_labs,ruby project/scripts/labs.rb --format pdf)

labs-list: labs-image
	$(call run_labs,ruby project/scripts/labs.rb --list)

# Example: make labs-ruby ARGS='project/scripts/example.rb'
labs-ruby: labs-image
	$(call run_labs,ruby $(ARGS))

help:
	@echo 'make lectures-slides      Build all lecture slides and copy to public/lectures/slides/'
	@echo 'make lectures             Alias for lectures-slides'
	@echo 'make lecture-dev LECTURE=<topic>/<lecture>  Run Slidev dev server for one lecture'
	@echo '                 [HOST=0.0.0.0] [PORT=3030] [PASSWORD=...]  Listen address, port, remote-control password'
	@echo 'make labs                 Export every lab to HTML and PDF (default)'
	@echo 'make labs-html            Export HTML only'
	@echo 'make labs-pdf             Export PDF only'
	@echo 'make labs LAB=01-ex       Export one lab directory (or relative .adoc path)'
	@echo 'make labs-list            List discovered lab entry points'
	@echo 'make labs-ruby ARGS=...   Run a Ruby script inside the build container'
