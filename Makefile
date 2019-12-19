CONTAINER=farcaster-remote-agent

.PHONY: all docker push clean ssh_configs

ssh_configs:
	PORT=2222 PERMIT_TTY=yes MAX_SESSIONS=15 \
		 ../common/etc/build-sshd_config.sh > etc/ssh/sshd_config
	cp ../common/etc/ssh_config etc/ssh/ssh_config

docker: ssh_configs
	docker build -f docker/Dockerfile -t $(CONTAINER) .

push: docker
	docker tag $(CONTAINER):latest probely/$(CONTAINER):latest
	docker push probely/$(CONTAINER):latest

clean:
	docker rm -f $(CONTAINER) 2>/dev/null || true
