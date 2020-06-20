.PHONY: all clean deps build clean_package package archive build_package docker-alpine docker-debian

ARCH = darwin-x64-unknown
SKIP_CHROMIUM =
OUT =
DOCKER_TAG = dev

all: clean build

clean:
	rm -rf build

deps: node_modules

node_modules: package.json yarn.lock ## Install node modules.
	@echo "install frontend dependencies"
	yarn install --pure-lockfile --no-progress

build:
	yarn build

clean_package:
	./scripts/clean_target.sh ${ARCH} ${OUT}

package:
	./scripts/package_target.sh ${ARCH} ${SKIP_CHROMIUM} ${OUT}

archive:
	./scripts/archive_target.sh ${ARCH} ${OUT}

build_package: clean clean_package build package archive

docker-alpine:
	docker build -t grafana/grafana-image-renderer:${DOCKER_TAG} .

docker-debian:
	docker build -t grafana/grafana-image-renderer:${DOCKER_TAG}-debian -f debian.Dockerfile .

# Build docker image with buildx
# Experimental docker feature to build cross platform multi-architecture docker images
# https://docs.docker.com/buildx/working-with-buildx/
docker-buildx:
	export DOCKER_CLI_EXPERIMENTAL=enabled
	@if ! docker buildx ls | grep -q container-builder; then\
		docker buildx create --platform "linux/amd64,linux/arm64,linux/arm/v7" --name container-builder --use;\
	fi
	docker buildx build --platform "linux/amd64,linux/arm64,linux/arm/v7" \
		-t $(REPOSITORY):$(VERSION) \
		. --push

