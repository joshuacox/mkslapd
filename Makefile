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
run: DATADIR NAME TAG PASS DOMAIN prod phpldapadmin

init: DATADIR NAME TAG PASS DOMAIN rm runinit

prod: rm runprod

jessie:
	sudo bash local-jessie.sh

runinit:
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval DOMAIN := $(shell cat DOMAIN))
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-d \
	-p 389:389 \
	-p 636:636 \
	--hostname ${DOMAIN} \
	-e LDAP_DOMAIN=${DOMAIN} \
	-e LDAP_ADMIN_PASSWORD=${PASS} \
	-e LDAP_CONFIG_PASSWORD=${PASS} \
	-v $(DATADIR)/data:/var/lib/ldap \
	-v $(DATADIR)/config:/etc/ldap/slap.d \
	-t $(TAG)

runprod:
	$(eval NAME := $(shell cat NAME))
	$(eval DOMAIN := $(shell cat DOMAIN))
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval TAG := $(shell cat TAG))
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-d \
	--hostname ${DOMAIN} \
	-p 389:389 \
	-p 636:636 \
	-v $(DATADIR)/data:/var/lib/ldap \
	-v $(DATADIR)/config:/etc/ldap/slap.d \
	-t $(TAG)

kill:
	-@docker kill `cat cid`
	-@docker kill `cat phpldapadmincid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid
	-@docker rm `cat phpldapadmincid`
	-@rm phpldapadmincid

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

DATADIR:
	@while [ -z "$$DATADIR" ]; do \
		read -r -p "Enter the datadir you wish to associate with this container [DATADIR]: " DATADIR; echo "$$DATADIR">>DATADIR; cat DATADIR; \
	done ;

phpldapadmin: PHPLDAPADMIN_PORT phpldapadmincid

phpldapadmincid:
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval PHPLDAPADMIN_PORT := $(shell cat PHPLDAPADMIN_PORT))
	$(eval DOMAIN := $(shell cat DOMAIN))
	@docker run --name=$(NAME)-phpldapadmin \
	--cidfile="phpldapadmincid" \
	-d \
	-p ${PHPLDAPADMIN_PORT}:80 \
	-e PHPLDAPADMIN_HTTPS=false \
	--link ${NAME}:ldap-host \
	-e PHPLDAPADMIN_LDAP_HOSTS=ldap-host \
	-t osixia/phpldapadmin:0.6.12

prepopulate:
	cp -av prepopulate.tempate prepopulate

creds: DOMAIN PASS
	./showcreds
