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
$ make app.push

# docker-compose: "playground"-stack
$ make playground.up
$ curl http://localhost/version.txt
$ make playground.down.v

# push docker image
$ make app.push DOCKER_USER=foo DOCKER_PASSWORD=bar

```
