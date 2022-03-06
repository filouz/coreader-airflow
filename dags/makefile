


DAGS_DIR=$(ROOT_DIR)/dags

#######################################################
#######################################################


dags_setup:
	cd docker/ && docker compose up -d;
	$(MAKE) dags_dev

dags_clean:
	-docker kill dags;
	-cd docker/ && docker compose down

dags_dev: dags_dev_build dags_dev_run

dags_dev_build:
	docker build $(DAGS_DIR) -t $(REGISTRY)/coreader/dags_builder:$(TAG)

dags_dev_run:
	docker run -it --rm \
		--name dags \
		--network dags-network \
		-w /repo \
		-v $(DAGS_DIR)/src:/repo \
		-v $(DAGS_DIR)/.cache/virtualenvs:/root/.cache/pypoetry/virtualenvs \
		$(REGISTRY)/coreader/dags_builder:$(TAG) \
		zsh

