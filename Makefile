.PHONY: vendors data_dirs

CURRENT_UID=$(shell id -u)
CURRENT_GID=$(shell id -g)

init:
	docker-compose run --rm cli /bin/bash -l -c "make vendors"
	docker-compose run --rm cli /bin/bash -l -c "grunt"

vendors: node_modules vendor .vendors/bundler

composer.phar:
	$(eval EXPECTED_SIGNATURE = "$(shell wget -q -O - https://composer.github.io/installer.sig)")
	$(eval ACTUAL_SIGNATURE = "$(shell php -r "copy('https://getcomposer.org/installer', 'composer-setup.php'); echo hash_file('SHA384', 'composer-setup.php');")")
	@if [ "$(EXPECTED_SIGNATURE)" != "$(ACTUAL_SIGNATURE)" ]; then echo "Invalid signature"; exit 1; fi
	php composer-setup.php
	rm composer-setup.php

vendor: composer.phar app/config/parameters.yml
	php composer.phar install

node_modules:
	npm install

.vendors/bundler:
	bundle install --path .vendors/bundler

app/config/parameters.yml:
	cp app/config/parameters.yml.dist app/config/parameters.yml

docker-up: app/logs/.docker-build data_dirs
	docker-compose up

docker-build: app/logs/.docker-build

app/logs/.docker-build: docker-compose.yml docker-compose.override.yml $(shell find docker/dockerfiles -type f)
	docker-compose rm --force
	CURRENT_UID=$(CURRENT_UID) CURRENT_GID=$(CURRENT_GID) docker-compose build
	touch app/logs/.docker-build

data_dirs: docker/data docker/data/composer

docker/data:
	mkdir -p docker/data

docker/data/composer: docker/data
	mkdir -p docker/data/composer

docker-compose.override.yml:
	cp docker-compose.override.yml-dist docker-compose.override.yml
