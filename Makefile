IMAGE_NAME:=jecklgamis/grpc-go-example
IMAGE_TAG:=main

BUILD_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
BUILD_VERSION:=$(shell git rev-parse HEAD)
BUILD_OS:=darwin
BUILD_ARCH:=amd64
LD_FLAGS:="-X github.com/jecklgamis/grpc-go-example/pkg/version.BuildVersion=$(BUILD_VERSION) \
		  -X github.com/jecklgamis/grpc-go-example/pkg/version.BuildBranch=$(BUILD_BRANCH)"

default:
	cat ./Makefile

install-deps:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway
	go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2

.PHONY: build
build: protobufs gateway-protobufs client-$(BUILD_OS)-$(BUILD_ARCH) server-$(BUILD_OS)-$(BUILD_ARCH) gateway-$(BUILD_OS)-$(BUILD_ARCH)

.PHONY: protobufs
protobufs:
	protoc -I . \
	--go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           pkg/kvstore/kvstore.proto
gateway-protobufs:
	protoc -I. \
	-I$(GOPATH)/src \
	--grpc-gateway_out=logtostderr=true,grpc_api_configuration=pkg/kvstore/kvstore.yaml:. pkg/kvstore/kvstore.proto

.PHONY: server
server-$(BUILD_OS)-$(BUILD_ARCH): server-linux-amd64
	@go build -o bin/$@ cmd/server/server.go
	@chmod +x bin/$@
server-linux-amd64:
	@echo "Building $@"
	@GOOS=linux GOARCH=amd64 go build -ldflags $(LD_FLAGS) -o bin/$@ cmd/server/server.go
	@chmod +x bin/$@
.PHONY: gateway
gateway-$(BUILD_OS)-$(BUILD_ARCH): gateway-linux-amd64
	@go build -o bin/$@ cmd/gateway/gateway.go
	@chmod +x bin/$@
gateway-linux-amd64:
	@echo "Building $@"
	@GOOS=linux GOARCH=amd64 go build -ldflags $(LD_FLAGS) -o bin/$@ cmd/gateway/gateway.go
	@chmod +x bin/$@

.PHONY: client
client-$(BUILD_OS)-$(BUILD_ARCH): client-linux-amd64
	go build -o bin/$@ cmd/client/client.go
	@chmod +x bin/$@
client-linux-amd64:
	@echo "Building $@"
	@GOOS=linux GOARCH=amd64 go build -ldflags $(LD_FLAGS) -o bin/$@ cmd/client/client.go
	@chmod +x bin/$@
.PHONY: clean
clean:
	@rm -f bin/*
	@rm -f pkg/kvstore/*.go
all: build image

image:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
run:
	docker run -p 4000:4000  -p 8080:8080 $(IMAGE_NAME):$(IMAGE_TAG)
run-bash:
	docker run -i -t $(IMAGE_NAME):$(IMAGE_TAG) /bin/bash
up:  all run