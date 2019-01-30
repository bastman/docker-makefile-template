SERVICE_NAME=hello-nginx
SERVICE_VERSION_FILE=./version.txt
GIT_BRANCH_NAME=$(shell git rev-parse --abbrev-ref HEAD | tr "/" "-")
GIT_COMMIT_HASH=$(shell git rev-parse HEAD | cut -c 1-8)
SERVICE_BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H.%M.%SZ")
SERVICE_VERSION ?=$(shell cat $(SERVICE_VERSION_FILE))
PWD=$(shell pwd)
DOCKER_COMPOSE_DIR="docker"

# config: docker: app
DOCKER_APP_REGISTRY=hub.docker.com
DOCKER_APP_REPOSITORY_NAME=$(SERVICE_NAME)
DOCKER_APP_REPOSITORY_FULLNAME=$(DOCKER_APP_REGISTRY)/$(DOCKER_APP_REPOSITORY_NAME)
DOCKER_APP_DOCKERFILE=docker/app/Dockerfile
DOCKER_APP_TAG_LOCAL=local/$(SERVICE_NAME):$(SERVICE_VERSION)

# misc
ifeq ($(shell cat $(SERVICE_VERSION_FILE)),)
SERVICE_VERSION := $(SERVICE_BUILD_TIME)-$(GIT_COMMIT_HASH)-$(GIT_BRANCH_NAME)
$(shell echo $(SERVICE_VERSION) > $(SERVICE_VERSION_FILE))
@echo "(new) service.version: $(SERVICE_VERSION)"
endif

print-%: ; @echo $*=$($*)
guard-%:
	@test ${${*}} || (echo "FAILED! Environment variable $* not set " && exit 1)
	@echo "-> use env var $* = ${${*}}";

.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<



version.show: guard-SERVICE_VERSION
	@echo "service.version: $(SERVICE_VERSION)"
version.clean:
	rm -f -v $(SERVICE_VERSION_FILE)
	$(eval SERVICE_VERSION := "")
	@echo "service.version: $(SERVICE_VERSION)"
version.set: guard-NEW_SERVICE_VERSION
	@echo "$(NEW_SERVICE_VERSION)" > $(SERVICE_VERSION_FILE)
version.generate: version.clean
	$(eval SERVICE_VERSION := $(SERVICE_BUILD_TIME)-$(GIT_COMMIT_HASH)-$(GIT_BRANCH_NAME))
	$(shell echo $(SERVICE_VERSION) > $(SERVICE_VERSION_FILE))
	@echo "(new) service.version: $(SERVICE_VERSION)"

##### docker-compose (common) #####

## docker-compose.up   : stack up
docker-compose.up: guard-DOCKER_COMPOSE_CONCERN
	docker-compose -f $(DOCKER_COMPOSE_DIR)/docker-compose-$(DOCKER_COMPOSE_CONCERN).yml up
## docker-compose.down   : stack down
docker-compose.down:
	docker-compose -f $(DOCKER_COMPOSE_DIR)/docker-compose-$(DOCKER_COMPOSE_CONCERN).yml down
## docker-compose.down.v   : stack down and remove volumes
docker-compose.down.v:
	docker-compose -f $(DOCKER_COMPOSE_DIR)/docker-compose-$(DOCKER_COMPOSE_CONCERN).yml down -v


######## app #####

## app.version   : show version
app.version:
	@echo "$(SERVICE_VERSION)"
## app.clean   : clean
app.clean: version.clean
	#@echo "clean: you may want to add ./gradlew clean here"
## app.build   : clean and build (jar, docker)
app.build: guard-SERVICE_VERSION
	@echo "build start: service $(SERVICE_NAME) version $(SERVICE_VERSION) --> docker-tag $(DOCKER_APP_TAG_LOCAL)"
	#@echo "clean: you may want to add ./gradlew build here"
	@echo "$(SERVICE_VERSION)" > docker/app/version.txt
	docker build -t $(DOCKER_APP_TAG_LOCAL) -f $(DOCKER_APP_DOCKERFILE) .
	@echo "- docker build: complete"
	@echo "build complete: service $(SERVICE_NAME) version $(SERVICE_VERSION) --> docker-tag $(DOCKER_APP_TAG_LOCAL)"
## app.clean-build   : build (jar, docker) - without tests
app.clean-build: app.clean version.generate app.build
## app.push   : push image to registry
app.push: guard-SERVICE_VERSION guard-DOCKER_USER guard-DOCKER_PASSWORD
	$(eval DOCKER_APP_TAG_REMOTE := "$(DOCKER_APP_REPOSITORY_FULLNAME):$(SERVICE_VERSION)")
	@echo "PUSH start: service $(SERVICE_NAME) version $(SERVICE_VERSION) --> docker-tag $(DOCKER_APP_TAG_REMOTE)"
	@echo "docker-tag: tag-local: $(DOCKER_APP_TAG_LOCAL) -> tag-remote: $(DOCKER_APP_TAG_REMOTE) ..."
	docker tag $(DOCKER_APP_TAG_LOCAL) $(DOCKER_APP_TAG_REMOTE)
	docker login $(DOCKER_APP_REGISTRY) -u $(DOCKER_USER) -p $(DOCKER_PASSWORD)
	docker push $(DOCKER_APP_TAG_REMOTE)

######## docker-stacks: playground #####

## playground.up   : build app & db and run compose stack "playground"
playground.up: app.clean-build playground.start
## playground.start   : start compose stack "playground"
playground.start: guard-SERVICE_VERSION
	make docker-compose.up DOCKER_COMPOSE_CONCERN=playground APP_IMAGE_TAG=$(DOCKER_APP_TAG_LOCAL)
## playground.down   : stop compose stack "playground"
playground.down: guard-SERVICE_VERSION
	make docker-compose.down DOCKER_COMPOSE_CONCERN=playground APP_IMAGE_TAG=$(DOCKER_APP_TAG_LOCAL)
## playground.down.v   : stop compose stack "playground" and remove volumes
playground.down.v: guard-SERVICE_VERSION
	make docker-compose.down.v DOCKER_COMPOSE_CONCERN=playground APP_IMAGE_TAG=$(DOCKER_APP_TAG_LOCAL)


