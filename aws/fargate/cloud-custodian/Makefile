TFENV_ROOT=$(HOME)/.tfenv
export PATH := $(TFENV_ROOT)/bin:$(PATH)
TFENV_VERSION := $(shell cat .terraform-version)

all: setup plan deploy

setup:
	if [ ! -d $(TFENV_ROOT) ]; then git clone https://github.com/kamatama41/tfenv.git $(TFENV_ROOT); fi
	$(TFENV_ROOT)/bin/tfenv install $(TFENV_VERSION)
	terraform init

test:
	docker-compose build
	docker-compose run custodian

plan: setup
	terraform plan

build: setup
	terraform apply -target=aws_ecr_repository.cloud-custodian
	docker build -t cloud-custodian .

deploy: build
	$(eval REPO_URL := $(shell terraform output cloud_custodian_repository_url | tr -d '\n'))
	$(eval CLUSTER := $(shell terraform output cluster | tr -d '\n'))
	docker tag cloud-custodian:latest $(REPO_URL):latest
	aws ecr get-login --region us-east-1 --no-include-email | sh -
	docker push $(REPO_URL):latest
	terraform apply
	aws ecs stop-task --task $(shell aws ecs describe-tasks --tasks $(shell aws ecs list-tasks --cluster $(CLUSTER) | jq -r .taskArns[] | xargs echo) --cluster $(CLUSTER) | jq -r '.tasks[] | select(.group == "service:cloud-custodian") | .taskArn') --cluster $(CLUSTER)

clean:
	terraform destroy -force security_group_id=$(SECURITY_GROUP_ID) -var subnet_id=$(SUBNET_ID) -auto-approve
