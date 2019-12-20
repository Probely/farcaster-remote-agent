CONTAINER=farcaster-remote-agent

.PHONY: all docker push clean

docker:
	docker build -f docker/Dockerfile -t $(CONTAINER) .

docker-alpine:
	docker build -f docker/alpine/Dockerfile -t $(CONTAINER) .

push: docker
	docker tag $(CONTAINER):latest probely/$(CONTAINER):latest
	docker push probely/$(CONTAINER):latest

clean:
	docker rm -f $(CONTAINER) 2>/dev/null || true
