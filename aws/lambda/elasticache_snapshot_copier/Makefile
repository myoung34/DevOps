PYENV_ROOT=$(HOME)/.pyenv
TFENV_ROOT=$(HOME)/.tfenv
TFENV_VERSION := $(shell cat .terraform-version)
export PATH := $(PYENV_ROOT)/bin:$(TFENV_ROOT)/bin:$(PATH)

all: setup-python setup-terraform deploy

setup-python:
	if [ ! -d $(PYENV_ROOT) ]; then git clone https://github.com/pyenv/pyenv.git $(PYENV_ROOT); eval "$(pyenv init -)"; if [ ! "$(shell pyenv versions | grep 3.6.0)" ]; then pyenv install 3.6.0; pyenv local 3.6.0; fi; fi;
	pip install virtualenv docker-compose

setup-terraform:
	if [ ! -d $(TFENV_ROOT) ]; then git clone https://github.com/kamatama41/tfenv.git $(TFENV_ROOT); fi
	$(TFENV_ROOT)/bin/tfenv install $(TFENV_VERSION)

zip:
	rm -rf lambda_elasticache_snapshot_copier.zip
	zip -r lambda_elasticache_snapshot_copier.zip lambda_function.py

test:
	docker-compose run lambda

plan: zip
	terraform init
	terraform plan

deploy: zip
	terraform init
	terraform apply -auto-approve
