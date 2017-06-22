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

prod: rm runprod

jessie:
	sudo bash local-jessie.sh

runprod:
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval DOMAIN := $(shell cat DOMAIN))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-p 389:389 \
	-p 636:636 \
	-e SLAPD_PASSWORD=${PASS} \
	-e SLAPD_DOMAIN=${DOMAIN} \
	-e SLAPD_ADDITIONAL_SCHEMAS=collective,corba,duaconf,dyngroup,java,misc,openldap,pmi,policy \
	-e SLAPD_ADDITIONAL_MODULES=memberof,ppolicy \
	-v $(DATADIR)/data:/var/lib/ldap \
	-v $(DATADIR)/config:/etc/ldap \
	-v ${PWD}/prepopulate:/etc/ldap.dist/prepopulate \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)

kill:
	-@docker kill `cat cid`

rm-image:
	-@docker rm `cat cid`
	-@rm cid

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

PHPLDADPADMIN_PORT:
	@while [ -z "$$PHPLDADPADMIN_PORT" ]; do \
		read -r -p "Enter the admin pass you wish to associate with this container [PHPLDADPADMIN_PORT]: " PHPLDADPADMIN_PORT; echo "$$PHPLDADPADMIN_PORT">>PHPLDADPADMIN_PORT; cat PHPLDADPADMIN_PORT; \
	done ;

DOMAIN:
	@while [ -z "$$DOMAIN" ]; do \
		read -r -p "Enter the domain you wish to associate with this container [DOMAIN]: " DOMAIN; echo "$$DOMAIN">>DOMAIN; cat DOMAIN; \
	done ;

DATADIR:
	@while [ -z "$$DATADIR" ]; do \
		read -r -p "Enter the datadir you wish to associate with this container [DATADIR]: " DATADIR; echo "$$DATADIR">>DATADIR; cat DATADIR; \
	done ;

phpldapadmin: PHPLDADPADMIN_PORT phpldapadmincid

phpldapadmincid:
	$(eval DATADIR := $(shell cat DATADIR))
	$(eval NAME := $(shell cat NAME))
	$(eval PWD := $(shell pwd))
	$(eval PASS := $(shell cat PASS))
	$(eval PHPLDADPADMIN_PORT := $(shell cat PHPLDADPADMIN_PORT))
	$(eval DOMAIN := $(shell cat DOMAIN))
	chmod 777 $(TMP)
	@docker run --name=$(NAME)-phpldapadmin \
	--cidfile="phpldapadmincid" \
	-d \
	-p ${PHPLDAPADMIN_PORT}:80 \
	-e PHPLDAPADMIN_HTTPS=false \
	--link ${NAME}:ldap-host \
	-e PHPLDAPADMIN_LDAP_HOSTS=ldap-host \
	-t osixia/phpldapadmin:0.6.12
