__PHONY__: run logs build build-deps build-deps-core build-deps-horizon build-deps-friendbot

REVISION=$(shell git -c core.abbrev=no describe --always --exclude='*' --long --dirty)
TAG?=latest
CORE_REPO?=https://github.com/stellar/stellar-core.git
CORE_REF?=master
CORE_CONFIGURE_FLAGS?=--disable-tests
HORIZON_REF?=master
FRIENDBOT_REF?=$(HORIZON_REF)

run:
	docker run --rm --name xdbchain -p 8000:8000 xdbchain/quickstart:$(TAG) --local

logs:
	docker exec xdbchain /bin/sh -c 'tail -F /var/log/supervisor/*'

console:
	docker exec -it xdbchain /bin/bash

build-latest:
	$(MAKE) build TAG=latest \
		CORE_REF=v20.3.0 \
		HORIZON_REF=horizon-v2.29.0 \

build-testing:
	$(MAKE) build TAG=testing \
		CORE_REF=v20.3.0 \
		HORIZON_REF=horizon-v2.29.0 \

build:
	$(MAKE) build-deps
	docker build --platform=linux/amd64 -t xdbchain/quickstart:$(TAG) -f Dockerfile . \
	  --build-arg REVISION=$(REVISION) \
	  --build-arg STELLAR_CORE_VERSION=$(CORE_VER) \
	  --build-arg HORIZON_VERSION=$(HORIZON_VER) \
	  --build-arg FRIENDBOT_IMAGE_REF=stellar-friendbot:$(FRIENDBOT_REF) \

build-deps: build-deps-friendbot

build-deps-core:
	docker build -t stellar-core:$(CORE_REF) -f docker/Dockerfile.testing $(CORE_REPO)#$(CORE_REF) --build-arg BUILDKIT_CONTEXT_KEEP_GIT_DIR=true --build-arg CONFIGURE_FLAGS="$(CORE_CONFIGURE_FLAGS)"

build-deps-horizon:
	docker build -t stellar-horizon:$(HORIZON_REF) -f Dockerfile.horizon --target builder . --build-arg REF="$(HORIZON_REF)"

build-deps-friendbot:
	docker build -t stellar-friendbot:$(FRIENDBOT_REF) -f services/friendbot/docker/Dockerfile https://github.com/stellar/go.git#$(FRIENDBOT_REF)
