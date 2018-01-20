.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

# run a plain container
run: DATADIR NAME TAG PASS DOMAIN LETSENCRYPT_EMAIL prod phpldapadmin

init: DATADIR NAME TAG PASS DOMAIN LETSENCRYPT_EMAIL rm runinit

prod: rm runprod

runinit: .nginx.cid .nginx-gen.cid .letsencrypt.cid
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	docker run --name=$(NAME) \
	--cidfile="cid" \
	-d \
	--expose 80 \
	-p 389:389 \
	-p 636:636 \
	--hostname ${DOMAIN} \
	-e LDAP_DOMAIN=${DOMAIN} \
	-e LDAP_ADMIN_PASSWORD=${PASS} \
	-e LDAP_CONFIG_PASSWORD=${PASS} \
	-e "VIRTUAL_HOST=$(DOMAIN)" \
	-e "LETSENCRYPT_HOST=$(DOMAIN)" \
	-e "LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL)" \
	-e LDAP_LOG_LEVEL="256" \
	-e LDAP_ORGANISATION="organisation" \
	-e LDAP_DOMAIN="domain" \
	-e LDAP_BASE_DN=${DOMAIN} \
	-e LDAP_READONLY_USER="false" \
	-e LDAP_BACKEND="hdb" \
	-e LDAP_TLS="true" \
	-e LDAP_TLS_CRT_FILENAME="$(DOMAIN).crt" \
	-e LDAP_TLS_KEY_FILENAME="$(DOMAIN).key" \
	-e LDAP_TLS_CA_CRT_FILENAME="$(DOMAIN).chain.pem" \
	-e LDAP_TLS_VERIFY_CLIENT="try" \
	-e LDAP_TLS_ENFORCE="false" \
	-e LDAP_REPLICATION="false" \
	-e LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
	-e LDAP_SSL_HELPER_PREFIX="ldap" \
	-v $(DATADIR)/data:/var/lib/ldap \
	-v $(DATADIR)/config:/etc/ldap/slapd.d \
	-v $(DATADIR)/certs/letsencrypt/archive/$(DOMAIN):/container/service/slapd/assets/certs:rw \
	-t $(TAG)

runprod: .nginx.cid .nginx-gen.cid .letsencrypt.cid
	$(eval NAME := $(shell cat NAME))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval TAG := $(shell cat TAG))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	docker run --name=$(NAME) \
	--cidfile="cid" \
	-d \
	--hostname ${DOMAIN} \
	--expose 80 \
	-p 389:389 \
	-p 636:636 \
	-e "VIRTUAL_HOST=$(DOMAIN)" \
	-e "LETSENCRYPT_HOST=$(DOMAIN)" \
	-e "LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL)" \
	-v $(DATADIR)/data:/var/lib/ldap \
	-v $(DATADIR)/config:/etc/ldap/slapd.d \
	-v $(DATADIR)/certs/letsencrypt/archive/$(DOMAIN):/container/service/slapd/assets/certs:rw \
	-t $(TAG)

kill:
	-@docker kill `cat cid`
	-@docker kill `cat .phpldapadmin.cid`
	-@docker kill `cat .letsencrypt.cid`
	-@docker kill `cat .nginx.cid`
	-@docker kill `cat .nginx-gen.cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid
	-@docker rm `cat .phpldapadmin.cid`
	-@rm .phpldapadmin.cid
	-@docker rm `cat .nginx.cid`
	-@rm .nginx.cid
	-@docker rm `cat .nginx-gen.cid`
	-@rm .nginx-gen.cid
	-@docker rm `cat .letsencrypt.cid`
	-@rm .letsencrypt.cid

rm: kill rm-image

clean: rm

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

PASS:
	@while [ -z "$$PASS" ]; do \
		read -r -p "Enter the admin pass you wish to associate with this container [PASS]: " PASS; echo "$$PASS">>PASS; cat PASS; \
	done ;

PHPLDAPADMIN_PORT:
	@while [ -z "$$PHPLDAPADMIN_PORT" ]; do \
		read -r -p "Enter the admin pass you wish to associate with this container [PHPLDAPADMIN_PORT]: " PHPLDAPADMIN_PORT; echo "$$PHPLDAPADMIN_PORT">>PHPLDAPADMIN_PORT; cat PHPLDAPADMIN_PORT; \
	done ;

DOMAIN:
	@while [ -z "$$DOMAIN" ]; do \
		read -r -p "Enter the domain you wish to associate with this container [DOMAIN]: " DOMAIN; echo "$$DOMAIN">>DOMAIN; cat DOMAIN; \
	done ;

LETSENCRYPT_EMAIL:
	@while [ -z "$$LETSENCRYPT_EMAIL" ]; do \
		read -r -p "Enter the admin email for letsencrypt you wish to associate with this container [LETSENCRYPT_EMAIL]: " LETSENCRYPT_EMAIL; echo "$$LETSENCRYPT_EMAIL">>LETSENCRYPT_EMAIL; cat LETSENCRYPT_EMAIL; \
	done ;

DATADIR:
	@while [ -z "$$DATADIR" ]; do \
		read -r -p "Enter the datadir you wish to associate with this container [DATADIR]: " DATADIR; echo "$$DATADIR">>DATADIR; cat DATADIR; \
	done ;

phpldapadmin: PHPLDAPADMIN_PORT .phpldapadmin.cid

.phpldapadmin.cid:
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval PHPLDAPADMIN_PORT := $(shell cat PHPLDAPADMIN_PORT))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval LETSENCRYPT_EMAIL := $(shell cat LETSENCRYPT_EMAIL))
	@docker run --name=$(NAME)-phpldapadmin \
	--cidfile=".phpldapadmin.cid" \
	-d \
	-p ${PHPLDAPADMIN_PORT}:80 \
	-e PHPLDAPADMIN_HTTPS=false \
	--link ${NAME}:ldap-host \
	-e "VIRTUAL_HOST=admin.$(DOMAIN)" \
	-e "LETSENCRYPT_HOST=admin.$(DOMAIN)" \
	-e "LETSENCRYPT_EMAIL=$(LETSENCRYPT_EMAIL)" \
	-e PHPLDAPADMIN_LDAP_HOSTS=ldap-host \
	-t osixia/phpldapadmin:0.6.12

prepopulate:
	cp -av prepopulate.template prepopulate

creds: DOMAIN PASS
	./showcreds

nginx: .nginx.cid

.nginx.cid:
	$(eval NAME := $(shell cat NAME))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval DATADIR := $(shell cat DATADIR))
	docker run -d -p 80:80 -p 443:443 \
		--name $(NAME)-nginx \
		--cidfile=".nginx.cid" \
		-v $(DATADIR)/nginx/conf.d:/etc/nginx/conf.d  \
		-v $(DATADIR)/nginx/vhost.d:/etc/nginx/vhost.d \
		-v $(DATADIR)/nginx/html:/usr/share/nginx/html \
		-v $(DATADIR)/certs/letsencrypt/archive/$(DOMAIN):/etc/nginx/certs:ro \
		--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy \
		nginx

nginx-gen: .nginx-gen.cid

.nginx-gen.cid: .nginx.cid
	$(eval NAME := $(shell cat NAME))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval DATADIR := $(shell cat DATADIR))
	docker run -d \
		--name $(NAME)-nginx-gen \
		--cidfile=".nginx-gen.cid" \
		--volumes-from $(NAME)-nginx \
		-v $(DATADIR)/templates/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
		-v /var/run/docker.sock:/tmp/docker.sock:ro \
		--label com.github.jrcs.letsencrypt_nginx_proxy_companion.docker_gen \
		jwilder/docker-gen \
		-notify-sighup $(NAME)-nginx -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

letsencrypt: .letsencrypt.cid

.letsencrypt.cid: .nginx.cid
	$(eval NAME := $(shell cat NAME))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval DATADIR := $(shell cat DATADIR))
	docker run -d \
		--name=$(NAME)-nginx-letsencrypt \
		--cidfile=".letsencrypt.cid" \
		-e NGINX_DOCKER_GEN_CONTAINER=$(NAME)-nginx-gen \
		-e NGINX_PROXY_CONTAINER=$(NAME)-nginx \
		-v $(DATADIR)/certs/letsencrypt/archive/$(DOMAIN):/etc/nginx/certs:rw \
		-v /var/run/docker.sock:/var/run/docker.sock:ro \
		--volumes-from $(NAME)-nginx \
		jrcs/letsencrypt-nginx-proxy-companion

TAG:
	cp -i TAG.example TAG
