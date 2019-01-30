# docker-makefile-template

A skeleton to build, run, push docker images.

Example: a simple nginx-alpine based image

- build and tag a docker image 

- tag: {{REPO}}:{{BUILD_TIME}}:{{GIT_COMMIT_HASH}}-{{GIT_BRANCH}}
```
    e.g: hello-nginx:2019-01-30T09.34.34Z-0a53ce69-master
    
    ... build from commit: https://github.com/bastman/docker-makefile-template/commit/0a53ce69
```    

```
# help
$ make help

# build docker image
$ make app.clean-build
# -> outputs: build complete: service hello-nginx version 2019-01-30T10.21.06Z-51677a70-master --> docker-tag local/hello-nginx:2019-01-30T10.21.06Z-51677a70-master
$ make app.push

# docker-compose: "playground"-stack
$ make playground.up
$ curl http://localhost/version.txt
$ make playground.down.v

# push docker image
$ make app.push DOCKER_USER=foo DOCKER_PASSWORD=bar

```

```
# how to inject a custom $SERVICE_VERSION ? (e.g. provided by a CI tool)
$ make app.clean
$ make version.set NEW_SERVICE_VERSION="v123"
$ make app.build
# -> outputs: build complete: service hello-nginx version v123 --> docker-tag local/hello-nginx:v123


```
