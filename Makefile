.DEFAULT_GOAL := labs

DOCKER ?= docker
NPM ?= npm
LABS_IMAGE ?= ossec-labs:local
LAB ?=
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
export LAB

.PHONY: labs labs-html labs-pdf labs-image labs-list labs-ruby lectures lectures-slides help

lectures: lectures-slides

lectures-slides:
	$(NPM) --prefix "$(ROOT)/project" run build:all
	$(NPM) --prefix "$(ROOT)/project" run copy:slides

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
	@echo 'make labs                 Export every lab to HTML and PDF (default)'
	@echo 'make labs-html            Export HTML only'
	@echo 'make labs-pdf             Export PDF only'
	@echo 'make labs LAB=01-ex       Export one lab directory (or relative .adoc path)'
	@echo 'make labs-list            List discovered lab entry points'
	@echo 'make labs-ruby ARGS=...   Run a Ruby script inside the build container'
