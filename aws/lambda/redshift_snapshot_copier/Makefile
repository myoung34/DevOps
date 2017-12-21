PYENV_ROOT=$(HOME)/.pyenv
TFENV_ROOT=$(HOME)/.tfenv
TFENV_VERSION := $(shell cat .terraform-version)
export PATH := $(PYENV_ROOT)/bin:$(TFENV_ROOT)/bin:$(PATH)

all: setup deploy

setup:
	if [ ! -d $(PYENV_ROOT) ]; then git clone https://github.com/pyenv/pyenv.git $(PYENV_ROOT); fi
	if [ ! -d $(TFENV_ROOT) ]; then git clone https://github.com/kamatama41/tfenv.git $(TFENV_ROOT); fi
	eval "$(pyenv init -)"
	if [ ! "$(shell pyenv versions | grep 3.6.0)" ]; then pyenv install 3.6.0; pyenv local 3.6.0; fi
	$(TFENV_ROOT)/bin/tfenv install $(TFENV_VERSION)
	terraform init

zip:
	rm -rf lambda_redshift_snapshot_copier.zip
	zip -r lambda_redshift_snapshot_copier.zip lambda_function.py

test:
	docker run -e AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) -e AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) -v "$(PWD)":/var/task lambci/lambda:python3.6

plan: zip
	terraform init
	terraform plan

deploy: zip
	terraform init
	terraform apply
